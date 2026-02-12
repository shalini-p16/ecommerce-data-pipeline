-- MERGE INTO `prism-486509.gold.dim_users` AS tgt
-- USING `prism-486509.silver.users` AS src
-- ON tgt.user_id = src.user_id AND tgt.is_current = TRUE

-- -- 1️⃣ Expire old version if attributes changed
-- WHEN MATCHED AND (
--      tgt.full_name        != src.full_name
--   OR tgt.age              != src.age
--   OR tgt.gender           != src.gender
--   OR tgt.city             != src.city
--   OR tgt.state            != src.state
--   OR tgt.country          != src.country
--   OR tgt.zip_code         != src.zip_code
--   OR tgt.street_address   != src.street_address
--   OR tgt.traffic_source   != src.traffic_source
-- )
-- THEN
--  UPDATE SET 
--     effective_to = CURRENT_DATE(),
--     is_current = FALSE

-- -- 2️⃣ Insert new version (new or changed user)
-- WHEN NOT MATCHED BY TARGET THEN
--   INSERT (
--     user_key,
--     user_id,
--     full_name,
--     age,
--     gender,
--     city,
--     state,
--     country,
--     zip_code,
--     street_address,
--     traffic_source,
--     signup_timestamp,
--     effective_from,
--     effective_to,
--     is_current
--   )
--   VALUES (
--     GENERATE_UUID(),
--     src.user_id,
--     src.full_name,
--     src.age,
--     src.gender,
--     src.city,
--     src.state,
--     src.country,
--     src.zip_code,
--     src.street_address,
--     src.traffic_source,
--     src.signup_timestamp,
--     CURRENT_DATE(),
--     DATE('9999-12-31'),
--     TRUE
--   );
MERGE INTO `prism-486509.gold.dim_users` AS tgt
USING `prism-486509.silver.users` AS src
ON tgt.user_id = src.user_id AND tgt.is_current = TRUE

-- 1️⃣ Expire old version if any attribute changed
WHEN MATCHED AND (
     tgt.full_name        != src.full_name
  OR tgt.age              != src.age
  OR tgt.gender           != src.gender
  OR tgt.city             != src.city
  OR tgt.state            != src.state
  OR tgt.country          != src.country
  OR tgt.zip_code         != src.zip_code
  OR tgt.street_address   != src.street_address
  OR tgt.traffic_source   != src.traffic_source
)
THEN
 UPDATE SET 
    effective_to = CURRENT_DATE(),
    is_current = FALSE

-- 2️⃣ Insert new version (new or changed user)
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    user_key,
    user_id,
    full_name,
    age,
    gender,
    city,
    state,
    country,
    zip_code,
    street_address,
    traffic_source,
    signup_timestamp,
    effective_from,
    effective_to,
    is_current
  )
  VALUES (
    TO_HEX(SHA256(CONCAT(CAST(src.user_id AS STRING), '|', CAST(CURRENT_DATE() AS STRING)))),  -- deterministic SCD2 key
    src.user_id,
    src.full_name,
    src.age,
    src.gender,
    src.city,
    src.state,
    src.country,
    src.zip_code,
    src.street_address,
    src.traffic_source,
    src.signup_timestamp,
    CURRENT_DATE(),
    DATE('9999-12-31'),
    TRUE
  );
