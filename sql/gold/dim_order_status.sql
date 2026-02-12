-- SELECT
--     TO_HEX(SHA256(order_status)) AS order_status_key,   -- UUID surrogate key
--     order_status ,         -- natural/business key      -- attribute
-- FROM (
--     SELECT DISTINCT 
--        order_status, 
--     FROM `prism-486509.silver.order_items`   -- source table with order status
-- ) AS distinct_statuses;

SELECT
    TO_HEX(SHA256(COALESCE(order_status, 'UNKNOWN'))) AS order_status_key,
    order_status
FROM (
    SELECT DISTINCT order_status
    FROM `prism-486509.silver.order_items`
    WHERE order_status IS NOT NULL
) AS distinct_statuses;

