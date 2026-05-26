import fs from 'fs';

function parseBracketTimestamp(line) {
  const match = line.match(/\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]/);
  if (!match) return null;
  const asUtc = new Date(match[1].replace(' ', 'T') + 'Z');
  if (Number.isNaN(asUtc.getTime())) return null;
  return asUtc;
}

export function parsePublishActionHealth(logText, now = new Date(), staleMinutes = 10) {
  const lines = typeof logText === 'string' ? logText.split('\n').slice(-200) : [];
  let evidenceLine = null;
  let lastSuccessAt = null;

  for (let i = lines.length - 1; i >= 0; i -= 1) {
    const line = lines[i];
    if (!line || !line.includes('publish-action complete.')) continue;
    evidenceLine = line.trim() || null;
    lastSuccessAt = parseBracketTimestamp(line);
    break;
  }

  if (!evidenceLine || !lastSuccessAt) {
    return { lastSuccessAt: null, evidenceLine, isStale: true };
  }

  const staleMs = staleMinutes * 60 * 1000;
  return {
    lastSuccessAt: lastSuccessAt.toISOString(),
    evidenceLine,
    isStale: now.getTime() - lastSuccessAt.getTime() > staleMs,
  };
}

export function readPublishActionHealth({ logPath, now = new Date(), staleMinutes = 10 }) {
  if (!logPath || !fs.existsSync(logPath)) {
    return { lastSuccessAt: null, evidenceLine: null, isStale: true };
  }
  const text = fs.readFileSync(logPath, 'utf8');
  return parsePublishActionHealth(text, now, staleMinutes);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const logPath = process.env.PUBLISH_ACTION_LOG || '/paperclip/logs/publish-action.log';
  const result = readPublishActionHealth({ logPath });
  console.log(JSON.stringify({ logPath, ...result }, null, 2));
}
