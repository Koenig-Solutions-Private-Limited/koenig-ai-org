import assert from 'node:assert/strict';
import { parsePublishActionHealth } from './publish_action_health.mjs';

const now = new Date('2026-05-28T03:12:00.000Z');

function legacyTickFilter(logText) {
  const line = logText.split('\n').slice(-200).filter((l) => /TICK|published/.test(l)).at(-1) || '';
  const m = line.match(/\[(.*?)\]/) || line.match(/(20\d\d-\d\d-\d\d[ T]\d\d:\d\d:\d\d(?:Z| UTC)?)/);
  if (!m) return null;
  const d = new Date(m[1].replace(' UTC', 'Z').replace(' ', 'T'));
  return Number.isNaN(+d) ? null : d.toISOString();
}

// Healthy no-op completion — legacy filter misses, new parser finds it.
const healthyNoOp = `[2026-05-28 03:05:22] Phase 2: scanning for publish_state=dispatching issues...
[2026-05-28 03:05:22] Phase 2: no dispatching issues found.
[2026-05-28 03:05:22] publish-action complete.
`;
const healthy = parsePublishActionHealth(healthyNoOp, now, 10);
assert.equal(legacyTickFilter(healthyNoOp), null, 'legacy /TICK|published/ filter must miss healthy no-op runs');
assert.equal(healthy.lastSuccessAt, '2026-05-28T03:05:22.000Z');
assert.equal(healthy.isStale, false);
assert.match(healthy.evidenceLine, /publish-action complete\./);

// Stale completion beyond 10-minute window.
const staleLog = `[2026-05-28 02:50:00] publish-action complete.\n`;
const stale = parsePublishActionHealth(staleLog, now, 10);
assert.equal(stale.isStale, true);
assert.equal(stale.lastSuccessAt, '2026-05-28T02:50:00.000Z');

// Old published line before newer completion — prefer newest completion.
const mixedLog = `[2026-05-28 03:00:00] published blog/foo.md
[2026-05-28 03:05:22] publish-action complete.
`;
const mixed = parsePublishActionHealth(mixedLog, now, 10);
assert.equal(mixed.lastSuccessAt, '2026-05-28T03:05:22.000Z');
assert.equal(mixed.isStale, false);

// Missing completion marker.
const missing = `[2026-05-28 03:05:22] Phase 1: no g4-approved issues found.\n`;
const missingResult = parsePublishActionHealth(missing, now, 10);
assert.equal(missingResult.lastSuccessAt, null);
assert.equal(missingResult.evidenceLine, null);
assert.equal(missingResult.isStale, true);

// Malformed timestamp on completion line.
const malformed = `[not-a-date] publish-action complete.\n`;
const malformedResult = parsePublishActionHealth(malformed, now, 10);
assert.equal(malformedResult.lastSuccessAt, null);
assert.equal(malformedResult.isStale, true);

console.log('publish_action_health fixtures: ok');
