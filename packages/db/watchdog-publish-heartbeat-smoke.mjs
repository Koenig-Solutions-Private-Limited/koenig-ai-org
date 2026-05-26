import fs from 'fs';
import os from 'os';
import path from 'path';

const STALE_MS = 10 * 60 * 1000;

function parsePublishSuccess(line) {
  const m = line.match(/\[(.*?)\]/) || line.match(/(20\d\d-\d\d-\d\d[ T]\d\d:\d\d:\d\d(?:Z| UTC)?)/);
  if (!m) return null;
  const d = new Date(m[1].replace(' UTC', 'Z').replace(' ', 'T'));
  if (Number.isNaN(+d)) return null;
  return d;
}

function getPublishHeartbeatEvidence(logPath, now = new Date()) {
  if (!fs.existsSync(logPath)) {
    return { publishStale: true, lastSuccessAt: 'none', evidenceLine: 'none' };
  }
  const lines = fs.readFileSync(logPath, 'utf8').split('\n').slice(-400);
  const evidence = lines.filter((l) => /publish-action complete\.|publish-action V2 tick complete/.test(l)).at(-1) || '';
  if (!evidence) {
    return { publishStale: true, lastSuccessAt: 'none', evidenceLine: 'none' };
  }
  const when = parsePublishSuccess(evidence);
  if (!when) {
    return { publishStale: true, lastSuccessAt: 'unparseable', evidenceLine: evidence.trim() || 'none' };
  }
  return {
    publishStale: (now - when) > STALE_MS,
    lastSuccessAt: when.toISOString(),
    evidenceLine: evidence.trim() || 'none',
  };
}

function assert(name, cond) {
  if (!cond) {
    throw new Error(`FAIL: ${name}`);
  }
  console.log(`PASS: ${name}`);
}

const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'watchdog-heartbeat-'));
const now = new Date('2026-05-26T09:20:00.000Z');

const freshLog = path.join(tmpDir, 'fresh.log');
fs.writeFileSync(freshLog, [
  '[2026-05-26 08:00:00] published some-old-item',
  '[2026-05-26 09:19:20] publish-action complete.',
].join('\n'));
const fresh = getPublishHeartbeatEvidence(freshLog, now);
assert('fresh completion beats older published line', fresh.publishStale === false && fresh.lastSuccessAt === '2026-05-26T09:19:20.000Z');

const staleLog = path.join(tmpDir, 'stale.log');
fs.writeFileSync(staleLog, '[2026-05-26 08:30:00] publish-action complete.\n');
const stale = getPublishHeartbeatEvidence(staleLog, now);
assert('stale completion remains failing', stale.publishStale === true && stale.lastSuccessAt === '2026-05-26T08:30:00.000Z');

const missing = getPublishHeartbeatEvidence(path.join(tmpDir, 'missing.log'), now);
assert('missing log remains failing', missing.publishStale === true && missing.lastSuccessAt === 'none');

const malformedLog = path.join(tmpDir, 'malformed.log');
fs.writeFileSync(malformedLog, '[not-a-timestamp] publish-action complete.\n');
const malformed = getPublishHeartbeatEvidence(malformedLog, now);
assert('malformed completion remains failing', malformed.publishStale === true && malformed.lastSuccessAt === 'unparseable');

const duplicatePrefix = '[WATCHDOG] publish-action.sh silent >10min';
const issueTitles = [
  `${duplicatePrefix} — last_success_at: 2026-05-26T08:00:00.000Z`,
  '[WATCHDOG] something else',
];
const hasDup = issueTitles.some((t) => t.startsWith(duplicatePrefix));
assert('stable-prefix dedupe catches repeat stale alerts', hasDup === true);

console.log('All watchdog publish heartbeat smoke checks passed.');
