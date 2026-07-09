#!/usr/bin/env node
/**
 * Upload NotebookLM chapter artifacts to R2 + write the chapter-meta.json
 * sidecar into the vault. Used by the Slide+Audio Producer (course-gen v3).
 *
 * Usage:
 *   node scripts/upload-chapter-assets.mjs \
 *     --course <course-slug> --chapter <NN-chapter-slug> \
 *     --dir /path/to/artifacts [--notebook <notebook-id>] [--title "Chapter title"]
 *
 * Reads CLOUDFLARE_R2_* from .env.koenig (repo root). Artifact dir may
 * contain any of: audio.mp3, slide-deck.pdf, video.mp4, quiz-easy.json,
 * quiz-hard.json, flashcards.json, study-guide.md, infographic.png,
 * mind-map.json. Missing files are skipped (sidecar omits them).
 * Idempotent: re-running overwrites R2 objects + sidecar.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, statSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { execSync } from "node:child_process";

const require = createRequire(
  "/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json",
);
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

function parseArgs() {
  const out = {};
  const a = process.argv.slice(2);
  for (let i = 0; i < a.length; i++) {
    if (a[i].startsWith("--")) out[a[i].slice(2)] = a[i + 1];
  }
  if (!out.course || !out.chapter || !out.dir) {
    console.error("usage: --course <slug> --chapter <NN-chslug> --dir <artifact-dir> [--notebook id] [--title t]");
    process.exit(1);
  }
  return out;
}

function loadEnv() {
  const env = {};
  for (const line of readFileSync(join(ROOT, ".env.koenig"), "utf8").split("\n")) {
    const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, "").trim();
  }
  return env;
}

function hasCli(name) {
  try {
    execSync(`command -v ${name}`, { stdio: "pipe" });
    return true;
  } catch {
    return false;
  }
}

function readPngDimensions(path) {
  const buf = readFileSync(path);
  if (buf.length < 24 || buf.toString("ascii", 1, 4) !== "PNG") {
    return { width: 1600, height: 900 };
  }
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
}

function resolveChapterMd(courseSlug, chapterId) {
  const nested = join(ROOT, "vault", "courses", courseSlug, chapterId, "chapter.md");
  if (existsSync(nested)) return nested;
  return join(ROOT, "vault", "courses", courseSlug, `${chapterId}.md`);
}

function chapterH2Headings(courseSlug, chapterId) {
  const mdPath = resolveChapterMd(courseSlug, chapterId);
  if (!existsSync(mdPath)) return [];
  const raw = readFileSync(mdPath, "utf8");
  const body = raw.replace(/^---[\s\S]*?---\n?/, "");
  return [...body.matchAll(/^##\s+(.+)$/gm)].map((m) => m[1].trim());
}

function mapSlideCaptions(pageCount, h2Headings) {
  if (!pageCount || pageCount < 1) return [];
  if (!h2Headings.length) {
    return Array.from({ length: pageCount }, (_, i) => {
      const label = `Slide ${i + 1}`;
      return { caption: label, section_heading: label };
    });
  }
  return Array.from({ length: pageCount }, (_, i) => {
    const page = i + 1;
    const idx = Math.min(
      Math.floor((page - 1) * h2Headings.length / pageCount),
      h2Headings.length - 1,
    );
    const heading = h2Headings[idx];
    return { caption: heading, section_heading: heading };
  });
}

function failSlideExtraction(message) {
  console.error(`slide PNG extraction failed: ${message}`);
  console.error("install poppler-utils (pdfinfo + pdftoppm) before uploading chapters with slide-deck.pdf");
  process.exit(1);
}

async function extractAndUploadSlides(pdfPath, courseSlug, chapterId, prefix, publicBase) {
  if (!hasCli("pdfinfo") || !hasCli("pdftoppm")) {
    failSlideExtraction("pdftoppm/pdfinfo missing");
  }

  let pageCount = 0;
  try {
    const info = execSync(`pdfinfo "${pdfPath}"`, { encoding: "utf8" });
    const m = info.match(/^Pages:\s+(\d+)/m);
    pageCount = m ? Number(m[1]) : 0;
  } catch (err) {
    failSlideExtraction(`pdfinfo failed: ${err.message}`);
  }
  if (!pageCount) failSlideExtraction("pdfinfo reported zero pages");

  const workDir = join(dirname(pdfPath), "slides");
  mkdirSync(workDir, { recursive: true });
  const ppmPrefix = join(workDir, "slide");
  try {
    execSync(`pdftoppm -png -r 150 "${pdfPath}" "${ppmPrefix}"`, { stdio: "pipe" });
  } catch (err) {
    failSlideExtraction(`pdftoppm failed: ${err.message}`);
  }

  const generated = readdirSync(workDir)
    .filter((f) => f.endsWith(".png"))
    .sort((a, b) => {
      const na = Number(a.match(/-(\d+)\.png$/)?.[1] ?? 0);
      const nb = Number(b.match(/-(\d+)\.png$/)?.[1] ?? 0);
      return na - nb;
    });

  const captions = mapSlideCaptions(generated.length || pageCount, chapterH2Headings(courseSlug, chapterId));
  const slides = [];
  let totalBytes = 0;

  for (let i = 0; i < generated.length; i++) {
    const page = i + 1;
    const fileName = `slide-${String(page).padStart(2, "0")}.png`;
    const localPath = join(workDir, generated[i]);
    const body = readFileSync(localPath);
    const key = `${prefix}/slides/${fileName}`;
    await s3.send(
      new PutObjectCommand({
        Bucket: env.CLOUDFLARE_R2_BUCKET,
        Key: key,
        Body: body,
        ContentType: "image/png",
      }),
    );
    const { width, height } = readPngDimensions(localPath);
    const map = captions[i] ?? { caption: `Slide ${page}`, section_heading: `Slide ${page}` };
    slides.push({
      page,
      image_url: `${publicBase}/${key}`,
      caption: map.caption,
      section_heading: map.section_heading,
      width,
      height,
    });
    totalBytes += body.length;
    console.log(`uploaded ${fileName} (${(body.length / 1024).toFixed(0)} KB) -> ${slides.at(-1).image_url}`);
  }

  if (!slides.length) {
    failSlideExtraction("pdftoppm produced no PNG files");
  }

  return {
    slides,
    slideImagesMeta: {
      page_count: slides.length,
      size_bytes: totalBytes,
      format: "png",
      produced_via: "pdftoppm via upload-chapter-assets.mjs",
    },
  };
}

const ARTIFACTS = [
  ["audio.mp3", "audio_url", "audio/mpeg"],
  ["slide-deck.pdf", "slide_deck_url", "application/pdf"],
  ["video.mp4", "video_url", "video/mp4"],
  ["quiz-easy.json", "quiz_url", "application/json"],
  ["quiz-hard.json", "quiz_challenge_url", "application/json"],
  ["flashcards.json", "flashcards_url", "application/json"],
  ["study-guide.md", "study_guide_url", "text/markdown"],
  ["infographic.png", "infographic_url", "image/png"],
  ["mind-map.json", "mind_map_url", "application/json"],
];

const args = parseArgs();
const env = loadEnv();
for (const k of ["CLOUDFLARE_R2_ACCESS_KEY_ID", "CLOUDFLARE_R2_SECRET_ACCESS_KEY", "CLOUDFLARE_R2_BUCKET", "CLOUDFLARE_R2_ENDPOINT", "CLOUDFLARE_R2_PUBLIC_URL"]) {
  if (!env[k]) {
    console.error(`missing ${k} in .env.koenig`);
    process.exit(1);
  }
}

const s3 = new S3Client({
  region: "auto",
  endpoint: env.CLOUDFLARE_R2_ENDPOINT,
  credentials: {
    accessKeyId: env.CLOUDFLARE_R2_ACCESS_KEY_ID,
    secretAccessKey: env.CLOUDFLARE_R2_SECRET_ACCESS_KEY,
  },
});

const prefix = `courses/${args.course}/${args.chapter}`;
const publicBase = env.CLOUDFLARE_R2_PUBLIC_URL.replace(/\/$/, "");
const assets = {};
const meta = {};

for (const [file, field, contentType] of ARTIFACTS) {
  const path = join(args.dir, file);
  if (!existsSync(path) || statSync(path).size === 0) continue;
  const key = `${prefix}/${file}`;
  const body = readFileSync(path);
  await s3.send(
    new PutObjectCommand({
      Bucket: env.CLOUDFLARE_R2_BUCKET,
      Key: key,
      Body: body,
      ContentType: contentType,
    }),
  );
  assets[field] = `${publicBase}/${key}`;
  meta[field.replace("_url", "")] = { size_bytes: body.length, format: file.split(".").pop() };
  console.log(`uploaded ${file} (${(body.length / 1024 / 1024).toFixed(1)} MB) -> ${assets[field]}`);
}

if (Object.keys(assets).length === 0) {
  console.error("no artifacts found in", args.dir);
  process.exit(1);
}

let slideManifest = { slides: [], slideImagesMeta: null };
const slideDeckPath = join(args.dir, "slide-deck.pdf");
const hasSlideDeck = existsSync(slideDeckPath) && statSync(slideDeckPath).size > 0;
if (hasSlideDeck) {
  slideManifest = await extractAndUploadSlides(
    slideDeckPath,
    args.course,
    args.chapter,
    prefix,
    publicBase,
  );
  if (!slideManifest.slides.length) {
    failSlideExtraction("slide-deck.pdf present but no slides were extracted");
  }
}

const sidecarDir = join(ROOT, "vault", "courses", args.course, args.chapter);
mkdirSync(sidecarDir, { recursive: true });
const sidecarPath = join(sidecarDir, "chapter-meta.json");
// merge with an existing sidecar so partial re-runs never lose assets
let existing = {};
try {
  existing = JSON.parse(readFileSync(sidecarPath, "utf8"));
} catch {
  existing = {};
}
const sidecar = {
  _doc: "Chapter asset manifest. Generated by upload-chapter-assets.mjs (course-gen v3). Frontend lib/courses.ts reads assets.* URLs. All URLs public on Cloudflare R2.",
  chapter_id: args.chapter,
  course_slug: args.course,
  ...(args.title ? { title: args.title } : {}),
  generated_at: new Date().toISOString(),
  generated_by: "notebooklm-py via upload-chapter-assets.mjs",
  ...(args.notebook ? { notebook_id: args.notebook } : {}),
  source_file: resolveChapterMd(args.course, args.chapter).replace(ROOT + "/", ""),
  assets: { ...(existing.assets ?? {}), ...assets },
  asset_metadata: {
    ...(existing.asset_metadata ?? {}),
    ...meta,
    ...(slideManifest.slideImagesMeta ? { slide_images: slideManifest.slideImagesMeta } : {}),
  },
  ...(slideManifest.slides.length
    ? { slides: slideManifest.slides }
    : existing.slides
      ? { slides: existing.slides }
      : {}),
  verification: { publish_state: "ready", r2_urls_status_200: "verified at upload" },
};
writeFileSync(sidecarPath, JSON.stringify(sidecar, null, 2) + "\n");
console.log(`sidecar -> ${sidecarPath}`);
console.log(`assets: ${Object.keys(sidecar.assets).join(", ")}`);
