
WITH DeduplicatedEvents AS (
  SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY id, created_at ORDER BY created_at) as rn -- Assuming id and created_at uniquely identify an event
  FROM
    `bronze.ext_events`
),
ValidatedAndCleanedEvents AS (
  SELECT
    -- Explicit Data Type Casting and Null Handling
    id, -- Already INT64, but included for completeness
    COALESCE(SAFE_CAST(user_id AS INT64), 0) AS user_id, -- Casts to INT64, replaces NULLs (from original or SAFE_CAST failure) with 0
    sequence_number, -- Already INT64
    COALESCE(session_id, 'UNKNOWN') AS session_id, -- Handles NULLs for STRING with 'UNKNOWN'
    created_at, -- Already TIMESTAMP
    COALESCE(ip_address, 'UNKNOWN') AS ip_address, -- Handles NULLs for STRING with 'UNKNOWN'
    COALESCE(city, 'UNKNOWN') AS city, -- Handles NULLs for STRING with 'UNKNOWN'
    COALESCE(state, 'UNKNOWN') AS state, -- Handles NULLs for STRING with 'UNKNOWN'
    COALESCE(postal_code, 'UNKNOWN') AS postal_code, -- Handles NULLs for STRING with 'UNKNOWN'
    COALESCE(browser, 'UNKNOWN') AS browser, -- Handles NULLs for STRING with 'UNKNOWN'
    COALESCE(traffic_source, 'UNKNOWN') AS traffic_source, -- Handles NULLs for STRING with 'UNKNOWN'
    COALESCE(uri, 'UNKNOWN') AS uri, -- Handles NULLs for STRING with 'UNKNOWN'
    COALESCE(event_type, 'UNKNOWN') AS event_type_cleaned, -- Handles NULLs for STRING, provides a default 'UNKNOWN', renamed to avoid conflict
    
    -- Basic Validation Checks
    CASE WHEN id IS NULL OR id <= 0 THEN FALSE ELSE TRUE END AS is_valid_id,
    CASE WHEN created_at IS NULL OR created_at > CURRENT_TIMESTAMP() THEN FALSE ELSE TRUE END AS is_valid_created_at,
    CASE
      WHEN event_type IN ('page_view', 'add_to_cart', 'purchase', 'login', 'signup', 'checkout') THEN TRUE
      ELSE FALSE
    END AS is_known_event_type


  FROM
    DeduplicatedEvents
  WHERE rn = 1 -- Keep only the first occurrence for deduplication
    AND id IS NOT NULL -- Exclude rows with a null 'id' as it's a critical identifier
)
SELECT
  id,
  user_id,
  sequence_number,
  session_id,
  created_at,
  ip_address,
  city,
  state,
  postal_code,
  browser,
  traffic_source,
  uri,
  event_type_cleaned AS event_type, -- Use the cleaned event_type
  is_valid_id,
  is_valid_created_at,
  is_known_event_type
FROM
  ValidatedAndCleanedEvents
WHERE
  is_valid_id = TRUE
  AND is_valid_created_at = TRUE
  AND is_known_event_type = TRUE; -- Filter to only include rows passing basic validation


