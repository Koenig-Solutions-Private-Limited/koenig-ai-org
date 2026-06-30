import assert from 'node:assert/strict';
import {
  ACTIVE_WATCHDOG_ISSUE_STATUSES,
  findActiveIssueByTitle,
  findFreshIssueByTitle,
} from './watchdog_issue_dedupe.mjs';

const BACKLOG_TITLE =
  '[WATCHDOG] Approval backlog exceeded 10 pending. Operator may want to triage.';
const COOLDOWN_MS = 4 * 60 * 60 * 1000;
const now = new Date('2026-05-26T18:00:00.000Z');

// KOEA-5081-style: blocked same-title issue older than 4h still suppresses duplicates.
const koea5081 = {
  id: '5081-id',
  title: BACKLOG_TITLE,
  status: 'blocked',
  hiddenAt: null,
  createdAt: '2026-05-26T13:53:00.000Z',
};
assert.equal(
  findActiveIssueByTitle([koea5081], BACKLOG_TITLE)?.id,
  '5081-id',
  'blocked issue older than 4h is an active duplicate',
);
assert.equal(
  findFreshIssueByTitle([koea5081], BACKLOG_TITLE, now, COOLDOWN_MS),
  null,
  'fresh-window dedupe does not treat >4h issue as duplicate',
);
assert.ok(
  findActiveIssueByTitle([koea5081], BACKLOG_TITLE),
  'KOEA-5110-style duplicate would be suppressed while KOEA-5081 remains active',
);

// Terminal statuses allow a new alert.
for (const status of ['done', 'cancelled']) {
  assert.equal(
    findActiveIssueByTitle(
      [{ ...koea5081, id: status, status }],
      BACKLOG_TITLE,
    ),
    null,
    `${status} same-title issue is not an active duplicate`,
  );
}

// Hidden issues are ignored.
assert.equal(
  findActiveIssueByTitle(
    [{ ...koea5081, hiddenAt: '2026-05-26T14:00:00.000Z' }],
    BACKLOG_TITLE,
  ),
  null,
  'hidden same-title issue is not an active duplicate',
);

// Fresh-window compatibility for timestamped/volatile titles.
const freshIssue = {
  id: 'fresh-id',
  title: '[WATCHDOG] publish-action.sh silent >10min — last tick: 2026-05-26T17:55:00.000Z',
  status: 'blocked',
  hiddenAt: null,
  createdAt: '2026-05-26T17:30:00.000Z',
};
assert.equal(
  findFreshIssueByTitle([freshIssue], freshIssue.title, now, COOLDOWN_MS)?.id,
  'fresh-id',
  'fresh-window dedupe matches recent same-title issue',
);
assert.equal(
  findActiveIssueByTitle([freshIssue], freshIssue.title)?.id,
  'fresh-id',
  'active dedupe also matches in-window blocked issue',
);

assert.deepEqual(ACTIVE_WATCHDOG_ISSUE_STATUSES, [
  'todo',
  'in_progress',
  'in_review',
  'blocked',
]);

console.log('watchdog_issue_dedupe.test.mjs: all assertions passed');
