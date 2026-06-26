#!/usr/bin/env node
/**
 * verify-status.mjs
 * Read-only lint: vault/blogs and vault/courses frontmatter `status:` values
 * must be one of the 8 canonical values in vault/STATUS.md.
 *
 * Run: node scripts/verify-status.mjs
 * Exit 0 when all statuses are canonical; exit 1 and print offenders otherwise.
 */

import { readFileSync, readdirSync } from 'fs';
import { resolve, join, relative } from 'path';
import { fileURLToPath } from 'url';

const REPO_ROOT = resolve(fileURLToPath(import.meta.url), '../..');

const CANONICAL = new Set([
  'draft',
  'awaiting-g0',
  'g0-blocked',
  'g0-passed',
  'g3-passed',
  'g4-approved',
  'published',
  'deprecated',
]);

const TARGET_FILENAMES = new Set(['draft.md', 'index.md', 'outline.md']);
const SCAN_DIRS = [
  join(REPO_ROOT, 'vault', 'blogs'),
  join(REPO_ROOT, 'vault', 'courses'),
];

function walkDir(dir, results = []) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return results;
  }
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      walkDir(full, results);
    } else if (entry.isFile() && TARGET_FILENAMES.has(entry.name)) {
      results.push(full);
    }
  }
  return results;
}

const invalid = [];

for (const dir of SCAN_DIRS) {
  const files = walkDir(dir);

  for (const absPath of files) {
    const content = readFileSync(absPath, 'utf8');

    if (!content.startsWith('---')) continue;
    const frontmatterEnd = content.indexOf('---', 3);
    if (frontmatterEnd === -1) continue;

    const frontmatter = content.slice(0, frontmatterEnd + 3);
    const statusMatch = frontmatter.match(/^(status:\s*)(\S+)/m);
    if (!statusMatch) continue;

    const currentValue = statusMatch[2].trim();

    if (!CANONICAL.has(currentValue)) {
      invalid.push({ file: relative(REPO_ROOT, absPath), value: currentValue });
    }
  }
}

if (invalid.length > 0) {
  console.error('Non-canonical vault status values found:');
  for (const { file, value } of invalid) {
    console.error(`  ${file}: status="${value}"`);
  }
  process.exit(1);
}

console.log('All vault status values are canonical.');
process.exit(0);
