-- ── Silver: Cleaned and deduplicated events ──────────────
WITH DeduplicatedEvents AS (
  SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY id ORDER BY created_at) AS rn
  FROM `prism-486509.bronze.events`
  WHERE ingestion_date = @run_date
),
ValidatedAndCleanedEvents AS (
  SELECT
    id,
    COALESCE(SAFE_CAST(user_id AS INT64), 0) AS user_id,
    sequence_number AS event_order_in_session,  -- bronze -> silver alias
    COALESCE(session_id, 'UNKNOWN') AS session_id,
    created_at,
    COALESCE(ip_address, 'UNKNOWN') AS ip_address,
    COALESCE(city, 'UNKNOWN') AS city,
    COALESCE(state, 'UNKNOWN') AS state,
    COALESCE(postal_code, 'UNKNOWN') AS postal_code,
    COALESCE(browser, 'UNKNOWN') AS browser,
    COALESCE(traffic_source, 'UNKNOWN') AS traffic_source,
    COALESCE(uri, 'UNKNOWN') AS uri,
    COALESCE(event_type, 'UNKNOWN') AS event_type_cleaned,
    CAST(ingestion_date AS DATE) AS ingestion_date,
  FROM DeduplicatedEvents
  WHERE rn = 1
    AND id IS NOT NULL
)
SELECT
  *
FROM ValidatedAndCleanedEvents;
