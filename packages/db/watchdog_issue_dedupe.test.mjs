import { describe, expect, test } from 'vitest';
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

describe('findActiveIssueByTitle', () => {
  test('blocked issue older than 4h is an active duplicate', () => {
    expect(findActiveIssueByTitle([koea5081], BACKLOG_TITLE)?.id).toBe('5081-id');
  });

  test('KOEA-5110-style duplicate would be suppressed while KOEA-5081 remains active', () => {
    expect(findActiveIssueByTitle([koea5081], BACKLOG_TITLE)).toBeTruthy();
  });

  test.each(['done', 'cancelled'])('%s same-title issue is not an active duplicate', (status) => {
    expect(
      findActiveIssueByTitle([{ ...koea5081, id: status, status }], BACKLOG_TITLE),
    ).toBeNull();
  });

  test('hidden same-title issue is not an active duplicate', () => {
    expect(
      findActiveIssueByTitle(
        [{ ...koea5081, hiddenAt: '2026-05-26T14:00:00.000Z' }],
        BACKLOG_TITLE,
      ),
    ).toBeNull();
  });

  test('active dedupe matches in-window blocked issue with timestamped title', () => {
    const freshIssue = {
      id: 'fresh-id',
      title: '[WATCHDOG] publish-action.sh silent >10min — last tick: 2026-05-26T17:55:00.000Z',
      status: 'blocked',
      hiddenAt: null,
      createdAt: '2026-05-26T17:30:00.000Z',
    };
    expect(findActiveIssueByTitle([freshIssue], freshIssue.title)?.id).toBe('fresh-id');
  });
});

describe('findFreshIssueByTitle', () => {
  test('fresh-window dedupe does not treat >4h issue as duplicate', () => {
    expect(findFreshIssueByTitle([koea5081], BACKLOG_TITLE, now, COOLDOWN_MS)).toBeNull();
  });

  test('fresh-window dedupe matches recent same-title issue', () => {
    const freshIssue = {
      id: 'fresh-id',
      title: '[WATCHDOG] publish-action.sh silent >10min — last tick: 2026-05-26T17:55:00.000Z',
      status: 'blocked',
      hiddenAt: null,
      createdAt: '2026-05-26T17:30:00.000Z',
    };
    expect(findFreshIssueByTitle([freshIssue], freshIssue.title, now, COOLDOWN_MS)?.id).toBe(
      'fresh-id',
    );
  });
});

describe('ACTIVE_WATCHDOG_ISSUE_STATUSES', () => {
  test('contains expected statuses', () => {
    expect(ACTIVE_WATCHDOG_ISSUE_STATUSES).toEqual(['todo', 'in_progress', 'in_review', 'blocked']);
  });
});
