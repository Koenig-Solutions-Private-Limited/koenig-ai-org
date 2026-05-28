import fs from 'node:fs';

const COMPLETION_MARKER = /publish-action complete\./;
const TIMESTAMP_PREFIX = /^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]/;

/**
 * Parse publish-action liveness from log text.
 * Scans the last 200 lines for the newest timestamped `publish-action complete.` line.
 */
export function parsePublishActionHealth(logText, now = new Date(), staleMinutes = 10) {
  const lines = String(logText ?? '').split('\n').slice(-200);
  let latest = null;

  for (const line of lines) {
    if (!COMPLETION_MARKER.test(line)) continue;
    const tsMatch = line.match(TIMESTAMP_PREFIX);
    if (!tsMatch) continue;
    const at = new Date(`${tsMatch[1].replace(' ', 'T')}Z`);
    if (Number.isNaN(+at)) continue;
    if (!latest || at > latest.at) {
      latest = { at, line: line.trim() };
    }
  }

  if (!latest) {
    return { lastSuccessAt: null, evidenceLine: null, isStale: true };
  }

  const staleMs = staleMinutes * 60 * 1000;
  const isStale = now - latest.at > staleMs;
  return {
    lastSuccessAt: latest.at.toISOString(),
    evidenceLine: latest.line,
    isStale,
  };
}

export function readPublishActionHealth({ logPath, now = new Date(), staleMinutes = 10 }) {
  if (!logPath || !fs.existsSync(logPath)) {
    return { lastSuccessAt: null, evidenceLine: null, isStale: true };
  }
  const logText = fs.readFileSync(logPath, 'utf8');
  return parsePublishActionHealth(logText, now, staleMinutes);
}
