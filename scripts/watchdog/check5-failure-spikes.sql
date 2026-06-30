WITH recent_failed AS (
  SELECT
    hr.id,
    hr.created_at,
    a.adapter_type,
    LEFT(
      COALESCE(
        NULLIF(BTRIM(hr.error), ''),
        NULLIF(BTRIM(hr.stderr_excerpt), ''),
        NULLIF(BTRIM(hr.error_code), ''),
        NULLIF(BTRIM(hr.result_json->>'error'), ''),
        'unknown_failure'
      ),
      60
    ) AS signature
  FROM heartbeat_runs hr
  JOIN agents a ON a.id = hr.agent_id
  WHERE hr.company_id = $1
    AND hr.created_at >= NOW() - INTERVAL '1 hour'
    AND hr.status = 'failed'
),
spikes AS (
  SELECT
    adapter_type,
    signature,
    COUNT(*)::int AS fail_count,
    (
      ARRAY_AGG(id::text ORDER BY created_at DESC)
    )[1:3] AS top_run_ids
  FROM recent_failed
  GROUP BY adapter_type, signature
  HAVING COUNT(*) >= 5
)
SELECT adapter_type, signature, fail_count, top_run_ids
FROM spikes
ORDER BY fail_count DESC, adapter_type, signature;
