import assert from 'node:assert/strict';
import { classifyFixtureRowsForTests } from './watchdog_stale_blocked.mjs';

const now = new Date('2026-05-27T04:00:00.000Z');
const old = '2026-05-10T00:00:00.000Z';
const recent = '2026-05-26T23:30:00.000Z';

const rows = [
  {
    id: '1', identifier: 'KOEA-3978', title: 'hourly-worker-dispatch chief marketing', company_id: 'c',
    status: 'in_progress', hidden_at: null, updated_at: old, last_movement_at: old,
    origin_kind: 'routine_execution', origin_id: 'o1', origin_fingerprint: 'f1', created_at: '2026-05-09T00:00:00.000Z',
    checkout_run_id: null, execution_run_id: null,
  },
  {
    id: '2', identifier: 'KOEA-3993', title: 'hourly-worker-dispatch chief marketing', company_id: 'c',
    status: 'blocked', hidden_at: null, updated_at: old, last_movement_at: recent,
    origin_kind: 'routine_execution', origin_id: 'o2', origin_fingerprint: 'f2', created_at: '2026-05-09T00:00:00.000Z',
    checkout_run_id: null, execution_run_id: null,
  },
  {
    id: '3', identifier: 'KOEA-5000', title: 'Manual integration blocker', company_id: 'c',
    status: 'blocked', hidden_at: null, updated_at: old, last_movement_at: old,
    origin_kind: 'manual', origin_id: null, origin_fingerprint: null, created_at: '2026-05-09T00:00:00.000Z',
    checkout_run_id: null, execution_run_id: null,
  },
  {
    id: '4', identifier: 'KOEA-5100', title: 'hourly-worker-dispatch chief marketing', company_id: 'c',
    status: 'blocked', hidden_at: null, updated_at: old, last_movement_at: old,
    origin_kind: 'routine_execution', origin_id: 'o3', origin_fingerprint: 'f3', created_at: '2026-05-09T00:00:00.000Z',
    checkout_run_id: null, execution_run_id: null,
  },
  {
    id: '5', identifier: 'KOEA-5101', title: 'hourly-worker-dispatch chief marketing', company_id: 'c',
    status: 'in_progress', hidden_at: null, updated_at: '2026-05-27T00:00:00.000Z', last_movement_at: '2026-05-27T00:00:00.000Z',
    origin_kind: 'routine_execution', origin_id: 'o3', origin_fingerprint: 'f3', created_at: '2026-05-27T00:00:00.000Z',
    checkout_run_id: null, execution_run_id: 'run-new',
  },
  {
    id: '6', identifier: 'KOEA-5102', title: 'daily-seo-dispatch', company_id: 'c',
    status: 'blocked', hidden_at: null, updated_at: old, last_movement_at: old,
    origin_kind: 'routine_execution', origin_id: 'o4', origin_fingerprint: 'f4', created_at: '2026-05-09T00:00:00.000Z',
    checkout_run_id: null, execution_run_id: null,
  },
  {
    id: '7', identifier: 'KOEA-5103', title: 'daily-seo-dispatch', company_id: 'c',
    status: 'done', hidden_at: null, updated_at: '2026-05-27T00:00:00.000Z', last_movement_at: '2026-05-27T00:00:00.000Z',
    origin_kind: 'routine_execution', origin_id: 'o4', origin_fingerprint: 'f4', created_at: '2026-05-27T00:00:00.000Z',
    checkout_run_id: null, execution_run_id: null,
  },
];

const { nudge, cleanup } = classifyFixtureRowsForTests(rows, { now, staleDays: 7 });
const nudgeIds = nudge.map((r) => r.id);
const cleanupIds = cleanup.map((r) => r.id);

assert(!nudgeIds.includes('1'), 'KOEA-3978 style non-blocked issue must be excluded');
assert(!nudgeIds.includes('2'), 'KOEA-3993 style recently moved issue must be excluded');
assert(nudgeIds.includes('3'), 'Genuinely blocked manual issue must be included in nudge list');
assert(cleanupIds.includes('4'), 'Superseded blocked hourly dispatch issue should be cleanup-only');
assert(!nudgeIds.includes('4'), 'Superseded blocked hourly dispatch issue should not be nudged');
assert(!cleanupIds.includes('6'), 'Non-hourly routine issue must never be included in cleanup payload');

console.log('watchdog_stale_blocked fixtures: ok');
