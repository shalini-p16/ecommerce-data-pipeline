-- SELECT
--   -- Surrogate key
--   GENERATE_UUID() AS event_key,
  
--   -- FKs from dimensions
--   id as event_id,
--   b.browser_key,
--   ts.traffic_source_key,
--   u.user_key,           -- ✅ Keep user_key
--   d.date_key,           -- ✅ Keep date_key
--   et.event_type_key,    -- ✅ Keep event_type_key
  
--   -- Measures
--   e.event_order_in_session,
--   e.session_id,         -- ✅ Add session_id
--   e.created_at AS event_timestamp

-- FROM `prism-486509.silver.events` e

-- -- User dimension ✅ Exists
-- LEFT JOIN `prism-486509.gold.dim_users` u
--   ON CAST(e.user_id AS STRING) = CAST(u.user_id AS STRING)

-- -- Browser dimension ✅ Exists  
-- LEFT JOIN `prism-486509.gold.dim_browser` b
--   ON e.browser = b.browser_name

-- -- Traffic source dimension ✅ Exists
-- LEFT JOIN `prism-486509.gold.dim_traffic_source` ts
--   ON e.traffic_source = ts.traffic_source

-- -- Event type dimension ✅ Exists
-- LEFT JOIN `prism-486509.gold.dim_event_type` et
--   ON e.event_type = et.event_type

-- -- Date dimension ✅ Exists
-- LEFT JOIN `prism-486509.gold.dim_date` d
--   ON DATE(e.created_at) = d.date

-- WHERE e.is_valid_id = TRUE 
--   AND e.is_valid_created_at = TRUE;

SELECT
  -- Deterministic surrogate key for fact row
  TO_HEX(SHA256(CAST(e.id AS STRING))) AS event_key,
  
  -- FKs from dimensions
  e.id AS event_id,
  b.browser_key,
  ts.traffic_source_key,
  u.user_key,
  d.date_key,
  et.event_type_key,
  l.location_key,
  
  -- Measures
  e.event_order_in_session,
  e.session_id,
  e.created_at AS event_timestamp

FROM `prism-486509.silver.events` e

LEFT JOIN `prism-486509.gold.dim_users` u
  ON CAST(e.user_id AS STRING) = CAST(u.user_id AS STRING)

LEFT JOIN `prism-486509.gold.dim_location` l
  ON e.city = l.city
  AND e.state = l.state
  AND e.postal_code = l.postal_code

LEFT JOIN `prism-486509.gold.dim_browser` b
  ON e.browser = b.browser_name

LEFT JOIN `prism-486509.gold.dim_traffic_source` ts
  ON e.traffic_source = ts.traffic_source

LEFT JOIN `prism-486509.gold.dim_event_type` et
  ON e.event_type_cleaned = et.event_type

LEFT JOIN `prism-486509.gold.dim_date` d
  ON DATE(e.created_at) = d.date

