#!/usr/bin/env node
/**
 * generate-chapter-audio.mjs
 * Production TTS pipeline for Koenig AI Academy course chapters.
 *
 * Provider order:
 *   1. Kokoro (OpenAI-compatible API at KOKORO_TTS_URL, default http://localhost:8888)
 *   2. OpenAI TTS (tts-1-hd, voice configurable via TTS_VOICE, default "nova")
 *
 * For each chapter:
 *   - Strips markdown to narrable plain text
 *   - Chunks text at sentence boundaries (≤4 000 chars per request)
 *   - Calls TTS provider, concatenates MP3 buffers
 *   - Uploads audio.mp3 to Cloudflare R2
 *   - Writes audio_url into chapter-meta.json (creates file if absent)
 *
 * Usage:
 *   node scripts/generate-chapter-audio.mjs --course <slug> --chapter <N>
 *   node scripts/generate-chapter-audio.mjs --course <slug> --all
 *   node scripts/generate-chapter-audio.mjs --course <slug> --all --skip-existing
 *
 * Required env vars:
 *   OPENAI_API_KEY
 *   CLOUDFLARE_R2_ACCESS_KEY_ID
 *   CLOUDFLARE_R2_SECRET_ACCESS_KEY
 *   CLOUDFLARE_R2_ENDPOINT          (e.g. https://<account>.r2.cloudflarestorage.com)
 *   CLOUDFLARE_R2_BUCKET            (e.g. koenig-academy-media)
 *   CLOUDFLARE_R2_PUBLIC_URL        (e.g. https://pub-xxx.r2.dev)
 *
 * Optional env vars:
 *   KOKORO_TTS_URL                  (default: http://localhost:8888)
 *   TTS_VOICE                       (default: nova)
 *   KOENIG_VAULT_ROOT               (default: /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault)
 */

import { createHmac, createHash } from "node:crypto";
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from "node:fs";
import { join, resolve } from "node:path";
import { parseArgs } from "node:util";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const VAULT_ROOT =
  process.env.KOENIG_VAULT_ROOT ||
  "/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault";

const R2_ACCESS_KEY = process.env.CLOUDFLARE_R2_ACCESS_KEY_ID;
const R2_SECRET_KEY = process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY;
const R2_ENDPOINT = process.env.CLOUDFLARE_R2_ENDPOINT;
const R2_BUCKET = process.env.CLOUDFLARE_R2_BUCKET;
const R2_PUBLIC_URL = process.env.CLOUDFLARE_R2_PUBLIC_URL?.replace(/\/$/, "");

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const KOKORO_URL = (process.env.KOKORO_TTS_URL || "http://localhost:8888").replace(/\/$/, "");
const TTS_VOICE = process.env.TTS_VOICE || "nova";

const TTS_CHUNK_SIZE = 3900; // chars per request (OpenAI max is 4096)

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

const { values: args } = parseArgs({
  options: {
    course: { type: "string" },
    chapter: { type: "string" },
    all: { type: "boolean", default: false },
    "skip-existing": { type: "boolean", default: false },
    "dry-run": { type: "boolean", default: false },
  },
  strict: false,
});

if (!args.course) {
  console.error("Usage: node scripts/generate-chapter-audio.mjs --course <slug> [--chapter <N> | --all] [--skip-existing] [--dry-run]");
  process.exit(1);
}

// ---------------------------------------------------------------------------
// SigV4 helpers for R2
// ---------------------------------------------------------------------------

function sha256hex(data) {
  return createHash("sha256").update(data).digest("hex");
}

function hmac(key, msg) {
  return createHmac("sha256", key).update(msg).digest();
}

function sigV4Auth(method, endpoint, bucket, key, body, contentType) {
  const url = new URL(`${endpoint}/${bucket}/${key}`);
  const now = new Date();

  // 20260502T114759Z format
  const amzDate = now.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
  const dateStr = amzDate.slice(0, 8);
  const region = "auto";
  const service = "s3";

  const bodyHash = sha256hex(body);
  const host = url.hostname;

  // Canonical request
  const canonHeaders =
    `content-type:${contentType}\n` +
    `host:${host}\n` +
    `x-amz-content-sha256:${bodyHash}\n` +
    `x-amz-date:${amzDate}\n`;
  const signedHeaders = "content-type;host;x-amz-content-sha256;x-amz-date";

  const canonPath = url.pathname;
  const canonRequest = [method, canonPath, "", canonHeaders, signedHeaders, bodyHash].join("\n");

  // String to sign
  const credScope = `${dateStr}/${region}/${service}/aws4_request`;
  const stringToSign =
    `AWS4-HMAC-SHA256\n${amzDate}\n${credScope}\n${sha256hex(canonRequest)}`;

  // Signing key
  const signingKey = hmac(
    hmac(hmac(hmac(Buffer.from(`AWS4${R2_SECRET_KEY}`, "utf8"), dateStr), region), service),
    "aws4_request",
  );

  const signature = createHmac("sha256", signingKey).update(stringToSign).digest("hex");

  return {
    url: url.toString(),
    headers: {
      Authorization: `AWS4-HMAC-SHA256 Credential=${R2_ACCESS_KEY}/${credScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
      "Content-Type": contentType,
      "x-amz-content-sha256": bodyHash,
      "x-amz-date": amzDate,
    },
  };
}

async function uploadToR2(r2Key, audioBuffer) {
  const { url, headers } = sigV4Auth("PUT", R2_ENDPOINT, R2_BUCKET, r2Key, audioBuffer, "audio/mpeg");

  const resp = await fetch(url, { method: "PUT", headers, body: audioBuffer });
  if (!resp.ok) {
    const body = await resp.text();
    throw new Error(`R2 upload failed ${resp.status}: ${body}`);
  }

  return `${R2_PUBLIC_URL}/${r2Key}`;
}

// ---------------------------------------------------------------------------
// Markdown → plain text
// ---------------------------------------------------------------------------

function markdownToText(md) {
  return md
    // Strip YAML frontmatter
    .replace(/^---[\s\S]*?---\n?/, "")
    // Strip fenced code blocks entirely (they shouldn't be narrated verbatim)
    .replace(/```[\s\S]*?```/g, "")
    .replace(/~~~[\s\S]*?~~~/g, "")
    // Strip inline code
    .replace(/`[^`]+`/g, (m) => m.slice(1, -1))
    // Strip wikilinks [[target|alias]] → alias or target
    .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, "$2")
    .replace(/\[\[([^\]]+)\]\]/g, "$1")
    // Strip markdown links [text](url) → text
    .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    // Strip images
    .replace(/!\[[^\]]*\]\([^)]*\)/g, "")
    // Strip headers → keep text with a pause
    .replace(/^#{1,6}\s+(.+)$/gm, "$1.")
    // Strip blockquotes marker
    .replace(/^>\s*/gm, "")
    // Strip horizontal rules
    .replace(/^[-*_]{3,}\s*$/gm, "")
    // Strip bold/italic markers
    .replace(/\*\*\*(.+?)\*\*\*/g, "$1")
    .replace(/\*\*(.+?)\*\*/g, "$1")
    .replace(/\*(.+?)\*/g, "$1")
    .replace(/___(.+?)___/g, "$1")
    .replace(/__(.+?)__/g, "$1")
    .replace(/_(.+?)_/g, "$1")
    // Strip footnote references [^N]
    .replace(/\[\^[^\]]+\]/g, "")
    // Strip table pipe chars — narrate cell content
    .replace(/\|/g, " ")
    // Collapse multiple blank lines to two
    .replace(/\n{3,}/g, "\n\n")
    // Trim
    .trim();
}

/** Split text into TTS-safe chunks at sentence boundaries. */
function chunkText(text, maxChars = TTS_CHUNK_SIZE) {
  const chunks = [];
  let remaining = text;

  while (remaining.length > maxChars) {
    // Find last sentence end before maxChars
    let cutAt = -1;
    const candidates = [...remaining.slice(0, maxChars).matchAll(/[.!?]\s/g)];
    if (candidates.length > 0) {
      const last = candidates[candidates.length - 1];
      cutAt = last.index + last[0].length;
    } else {
      // Fallback: split at last whitespace
      const wsIdx = remaining.slice(0, maxChars).lastIndexOf(" ");
      cutAt = wsIdx > 0 ? wsIdx + 1 : maxChars;
    }
    chunks.push(remaining.slice(0, cutAt).trim());
    remaining = remaining.slice(cutAt).trim();
  }

  if (remaining.length > 0) chunks.push(remaining.trim());
  return chunks;
}

// ---------------------------------------------------------------------------
// TTS: Kokoro (OpenAI-compatible) → OpenAI fallback
// ---------------------------------------------------------------------------

let kokoroAvailable = null;

async function probeKokoro() {
  if (kokoroAvailable !== null) return kokoroAvailable;
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 2000);
    const resp = await fetch(`${KOKORO_URL}/v1/models`, { signal: ctrl.signal });
    clearTimeout(t);
    kokoroAvailable = resp.ok;
  } catch {
    kokoroAvailable = false;
  }
  console.log(`[tts] Kokoro at ${KOKORO_URL}: ${kokoroAvailable ? "✓ reachable" : "✗ unavailable → falling back to OpenAI"}`);
  return kokoroAvailable;
}

async function ttsChunk(text, provider) {
  const apiUrl = provider === "kokoro" ? `${KOKORO_URL}/v1/audio/speech` : "https://api.openai.com/v1/audio/speech";
  const apiKey = provider === "kokoro" ? "kokoro" : OPENAI_API_KEY;
  const model = provider === "kokoro" ? "kokoro" : "tts-1-hd";

  const resp = await fetch(apiUrl, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      input: text,
      voice: TTS_VOICE,
      response_format: "mp3",
    }),
  });

  if (!resp.ok) {
    const body = await resp.text();
    throw new Error(`TTS ${provider} failed ${resp.status}: ${body}`);
  }

  return Buffer.from(await resp.arrayBuffer());
}

async function generateAudio(text) {
  const chunks = chunkText(text);
  console.log(`[tts] ${chunks.length} chunk(s), ${text.length} chars total`);

  const useKokoro = await probeKokoro();
  const provider = useKokoro ? "kokoro" : "openai";

  const buffers = [];
  for (let i = 0; i < chunks.length; i++) {
    process.stdout.write(`[tts] chunk ${i + 1}/${chunks.length} (${chunks[i].length} chars)…`);
    const buf = await ttsChunk(chunks[i], provider);
    buffers.push(buf);
    process.stdout.write(` ${buf.length} bytes ✓\n`);
  }

  return { buffer: Buffer.concat(buffers), provider };
}

// ---------------------------------------------------------------------------
// chapter-meta.json helpers
// ---------------------------------------------------------------------------

function loadOrCreateMeta(metaPath, chapterId, courseSlug, chapterTitle) {
  if (existsSync(metaPath)) {
    return JSON.parse(readFileSync(metaPath, "utf8"));
  }
  // Scaffold a new chapter-meta.json
  return {
    _doc: "Chapter asset manifest. Generated by generate-chapter-audio.mjs. Frontend (lib/courses.ts) reads this to populate per-chapter audio/slides/study-guide/mind-map/infographic/flashcards URLs.",
    chapter_id: chapterId,
    course_slug: courseSlug,
    title: chapterTitle,
    generated_at: new Date().toISOString(),
    generated_by: "generate-chapter-audio.mjs",
    source_file: `vault/courses/${courseSlug}/${chapterId}.md`,
    assets: {},
    asset_metadata: {},
    verification: {
      publish_state: "ready",
      all_urls_status_200: "to-verify",
      g5_verified_at: null,
    },
  };
}

function updateMetaAudio(meta, audioUrl, sizeBytes, provider) {
  meta.assets = meta.assets || {};
  meta.asset_metadata = meta.asset_metadata || {};

  meta.assets.audio_url = audioUrl;
  meta.asset_metadata.audio = {
    size_bytes: sizeBytes,
    format: "mp3",
    produced_via: `generate-chapter-audio.mjs (${provider})`,
    produced_at: new Date().toISOString(),
  };
  meta.generated_at = new Date().toISOString();
  meta.generated_by = `generate-chapter-audio.mjs (${provider})`;

  return meta;
}

// ---------------------------------------------------------------------------
// Core: process one chapter
// ---------------------------------------------------------------------------

async function processChapter(courseSlug, chapterFile, opts = {}) {
  const courseDir = join(VAULT_ROOT, "courses", courseSlug);
  const chapterId = chapterFile.replace(/\.md$/, "");
  const mdPath = join(courseDir, chapterFile);

  if (!existsSync(mdPath)) {
    console.error(`[skip] Chapter file not found: ${mdPath}`);
    return;
  }

  // Parse title from frontmatter
  const mdRaw = readFileSync(mdPath, "utf8");
  const titleMatch = mdRaw.match(/^title:\s*["']?(.+?)["']?\s*$/m);
  const chapterTitle = titleMatch ? titleMatch[1] : chapterId;

  // Paths
  const chapterDir = join(courseDir, chapterId);
  const metaPath = join(chapterDir, "chapter-meta.json");
  const r2Key = `courses/${courseSlug}/${chapterId}/audio.mp3`;
  const publicUrl = `${R2_PUBLIC_URL}/${r2Key}`;

  // Skip if audio already exists in meta
  if (opts.skipExisting && existsSync(metaPath)) {
    const existingMeta = JSON.parse(readFileSync(metaPath, "utf8"));
    if (existingMeta?.assets?.audio_url) {
      console.log(`[skip] ${chapterId}: audio_url already set → ${existingMeta.assets.audio_url}`);
      return;
    }
  }

  console.log(`\n[chapter] ${chapterId} — "${chapterTitle}"`);

  // Extract narrable text
  const plainText = markdownToText(mdRaw);
  console.log(`[text] ${plainText.length} chars after stripping markdown`);

  if (plainText.length < 100) {
    console.warn(`[warn] Very short text (${plainText.length} chars) — skipping`);
    return;
  }

  if (opts.dryRun) {
    console.log(`[dry-run] Would generate audio and upload to r2://${R2_BUCKET}/${r2Key}`);
    console.log(`[dry-run] Public URL would be: ${publicUrl}`);
    return;
  }

  // Generate audio
  const { buffer: audioBuffer, provider } = await generateAudio(plainText);
  console.log(`[audio] Total MP3 size: ${(audioBuffer.length / 1024 / 1024).toFixed(2)} MB`);

  // Upload to R2
  console.log(`[r2] Uploading to ${r2Key}…`);
  const uploadedUrl = await uploadToR2(r2Key, audioBuffer);
  console.log(`[r2] ✓ ${uploadedUrl}`);

  // Update chapter-meta.json
  mkdirSync(chapterDir, { recursive: true });
  const meta = loadOrCreateMeta(metaPath, chapterId, courseSlug, chapterTitle);
  updateMetaAudio(meta, uploadedUrl, audioBuffer.length, provider);
  writeFileSync(metaPath, JSON.stringify(meta, null, 2) + "\n", "utf8");
  console.log(`[meta] ✓ Wrote ${metaPath}`);

  return { chapterId, audioUrl: uploadedUrl, sizeBytes: audioBuffer.length, provider };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  // Validate required env
  const missing = ["CLOUDFLARE_R2_ACCESS_KEY_ID", "CLOUDFLARE_R2_SECRET_ACCESS_KEY",
    "CLOUDFLARE_R2_ENDPOINT", "CLOUDFLARE_R2_BUCKET", "CLOUDFLARE_R2_PUBLIC_URL",
    "OPENAI_API_KEY"].filter((k) => !process.env[k]);
  if (missing.length) {
    console.error(`Missing required env vars: ${missing.join(", ")}`);
    process.exit(1);
  }

  const courseSlug = args.course;
  const courseDir = join(VAULT_ROOT, "courses", courseSlug);

  if (!existsSync(courseDir)) {
    console.error(`Course directory not found: ${courseDir}`);
    process.exit(1);
  }

  const opts = {
    skipExisting: args["skip-existing"],
    dryRun: args["dry-run"],
  };

  let chapters = [];

  if (args.all) {
    // All .md files except outline.md, sorted numerically
    chapters = readdirSync(courseDir)
      .filter((f) => f.endsWith(".md") && f !== "outline.md")
      .sort();
    console.log(`[course] ${courseSlug}: found ${chapters.length} chapter(s)`);
  } else if (args.chapter) {
    // Find chapter by number prefix
    const padded = String(args.chapter).padStart(2, "0");
    const found = readdirSync(courseDir).find(
      (f) => f.startsWith(padded) && f.endsWith(".md"),
    );
    if (!found) {
      console.error(`Chapter ${args.chapter} not found in ${courseDir}`);
      process.exit(1);
    }
    chapters = [found];
  } else {
    console.error("Specify --all or --chapter <N>");
    process.exit(1);
  }

  const results = [];
  for (const ch of chapters) {
    try {
      const result = await processChapter(courseSlug, ch, opts);
      if (result) results.push(result);
    } catch (err) {
      console.error(`[error] ${ch}: ${err.message}`);
      console.error(err.stack);
    }
  }

  if (results.length > 0) {
    console.log(`\n✅ Done — ${results.length} chapter(s) processed:`);
    for (const r of results) {
      console.log(`   ${r.chapterId}: ${r.audioUrl} (${(r.sizeBytes / 1024 / 1024).toFixed(2)} MB, ${r.provider})`);
    }
  } else if (!opts.dryRun) {
    console.log("\n⚠️  No chapters processed (all skipped or errored).");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
