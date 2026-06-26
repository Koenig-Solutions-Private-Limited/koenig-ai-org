/** Shared watchdog issue dedupe helpers for stable vs fresh-title alerts. */

export const ACTIVE_WATCHDOG_ISSUE_STATUSES = ['todo', 'in_progress', 'in_review', 'blocked'];

/** Same-title issue in an active status (ignores age; excludes hidden). */
export function findActiveIssueByTitle(issues, title) {
  return (
    issues.find(
      (i) =>
        i.title === title &&
        !i.hiddenAt &&
        ACTIVE_WATCHDOG_ISSUE_STATUSES.includes(i.status),
    ) ?? null
  );
}

/** Same-title issue created within cooldownMs (legacy fresh-window dedupe). */
export function findFreshIssueByTitle(issues, title, now, cooldownMs) {
  const nowMs = now instanceof Date ? now.getTime() : Number(now);
  return (
    issues.find((i) => {
      if (i.title !== title || i.hiddenAt) return false;
      const createdMs = new Date(i.createdAt).getTime();
      return nowMs - createdMs <= cooldownMs;
    }) ?? null
  );
}
