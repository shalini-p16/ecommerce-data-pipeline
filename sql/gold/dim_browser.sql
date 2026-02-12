-- -- Just the SELECT part, destination set in job config
-- SELECT
--     TO_HEX(SHA256(browser)) AS browser_key, --Same browser → same key every run, Safe for incremental loads
--     browser AS browser_name
-- FROM (
--     SELECT DISTINCT browser
--     FROM `prism-486509.silver.events`
-- ) AS distinct_browsers

SELECT
    TO_HEX(SHA256(browser)) AS browser_key,  -- deterministic key
    browser AS browser_name
FROM (
    SELECT DISTINCT browser
    FROM `prism-486509.silver.events`
) AS distinct_browsers
