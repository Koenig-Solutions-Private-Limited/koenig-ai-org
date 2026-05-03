-- V5: server-side idempotency belt + suspenders
-- Prevents duplicate child ticket creation across simultaneous wakeups.
-- Window: 1-minute bucket. Same parent + agent + originKind in same minute = single ticket.
ALTER TABLE issues
  ADD CONSTRAINT idempotency_child_ticket_dedup
  UNIQUE NULLS NOT DISTINCT (
    "parentIssueId",
    "assignedAgentId",
    "originKind",
    (date_trunc('minute', "createdAt"))
  )
  WHERE "parentIssueId" IS NOT NULL;
