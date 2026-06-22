import assert from 'node:assert/strict';
import { parsePublishActionHealth } from './publish_action_health.mjs';

const now = new Date('2026-05-26T19:35:00.000Z');

const fixture = `
[2026-05-26 18:44:25] publish-action complete.
[2026-05-26 19:32:44] publish-action complete.
`;

const oldFilterLastTick = fixture
  .split('\n')
  .filter((line) => /TICK|published/.test(line))
  .at(-1) || 'none';
assert.equal(oldFilterLastTick, 'none');

const currentFailureFixed = parsePublishActionHealth(fixture, now, 10);
assert.equal(currentFailureFixed.lastSuccessAt, '2026-05-26T19:32:44.000Z');
assert.equal(currentFailureFixed.isStale, false);

const staleFixture = `[2026-05-26 18:00:00] publish-action complete.`;
const staleResult = parsePublishActionHealth(staleFixture, now, 10);
assert.equal(staleResult.lastSuccessAt, '2026-05-26T18:00:00.000Z');
assert.equal(staleResult.isStale, true);

const publishedBeforeCompletion = `
[2026-05-26 19:00:00] state=published
[2026-05-26 19:32:44] publish-action complete.
`;
const publishedBeforeCompletionResult = parsePublishActionHealth(publishedBeforeCompletion, now, 10);
assert.equal(publishedBeforeCompletionResult.lastSuccessAt, '2026-05-26T19:32:44.000Z');
assert.equal(publishedBeforeCompletionResult.isStale, false);

const missingTextResult = parsePublishActionHealth(null, now, 10);
assert.equal(missingTextResult.lastSuccessAt, null);
assert.equal(missingTextResult.isStale, true);

const malformedTimestamp = `[not-a-date] publish-action complete.`;
const malformedTimestampResult = parsePublishActionHealth(malformedTimestamp, now, 10);
assert.equal(malformedTimestampResult.lastSuccessAt, null);
assert.equal(malformedTimestampResult.isStale, true);

console.log('publish_action_health tests: PASS');
