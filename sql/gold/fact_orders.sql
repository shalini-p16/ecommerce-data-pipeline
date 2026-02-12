-- SELECT
--     -- Surrogate Key for fact_orders
--     GENERATE_UUID() AS order_key,

--     -- Natural key from silver.orders
--     o.order_id,

--     -- Foreign Key to dim_users
--     u.user_key,

--     -- Foreign Key to dim_order_status
--     os.order_status_key,

--     -- Foreign Keys to dim_date for each milestone (convert TIMESTAMP -> DATE)
--     dd_created.date_key AS created_at_key,
--     dd_shipped.date_key AS shipped_at_key,
--     dd_delivered.date_key AS delivered_at_key,
--     dd_returned.date_key AS returned_at_key,

--     -- Aggregated / Fact Measures
--     o.num_of_item,

--     -- Flags for accumulating snapshot
--     CASE WHEN o.delivered_at IS NOT NULL THEN TRUE ELSE FALSE END AS is_fully_completed,
--     CASE WHEN o.returned_at IS NOT NULL THEN TRUE ELSE FALSE END AS was_returned

-- FROM `prism-486509.silver.orders` AS o

-- -- Join to dim_users to get user_key
-- LEFT JOIN `prism-486509.gold.dim_users` AS u
--     ON CAST(o.user_id AS INTEGER) = CAST(u.user_id AS INTEGER)  

-- -- Join to dim_order_status to get order_status_key
-- LEFT JOIN `prism-486509.gold.dim_order_status` AS os
--     ON o.status = os.order_status

-- -- Join to dim_date for created_at
-- LEFT JOIN `prism-486509.gold.dim_date` AS dd_created
--     ON (o.created_at) = dd_created.date

-- -- Join to dim_date for shipped_at
-- LEFT JOIN `prism-486509.gold.dim_date` AS dd_shipped
--     ON DATE(o.shipped_at) = dd_shipped.date

-- -- Join to dim_date for delivered_at
-- LEFT JOIN `prism-486509.gold.dim_date` AS dd_delivered
--     ON DATE(o.delivered_at) = dd_delivered.date

-- -- Join to dim_date for returned_at
-- LEFT JOIN `prism-486509.gold.dim_date` AS dd_returned
--     ON DATE(o.returned_at) = dd_returned.date;

SELECT
    -- Deterministic surrogate key for fact_orders
    TO_HEX(SHA256(CAST(o.order_id AS STRING))) AS order_key,

    -- Natural key
    o.order_id,

    -- Foreign Key to dim_users
    u.user_key,

    -- Foreign Key to dim_order_status
    os.order_status_key,

    -- Foreign Keys to dim_date for each milestone
    dd_created.date_key AS created_at_key,
    dd_shipped.date_key AS shipped_at_key,
    dd_delivered.date_key AS delivered_at_key,
    dd_returned.date_key AS returned_at_key,

    -- Aggregated / Fact Measures
    o.num_of_item,

    -- -- Flags for snapshot
    -- CASE WHEN o.delivered_at IS NOT NULL THEN TRUE ELSE FALSE END AS is_fully_completed,
    -- CASE WHEN o.returned_at IS NOT NULL THEN TRUE ELSE FALSE END AS was_returned

FROM `prism-486509.silver.orders` AS o

LEFT JOIN `prism-486509.gold.dim_users` AS u
    ON CAST(o.user_id AS STRING) = CAST(u.user_id AS STRING)  

LEFT JOIN `prism-486509.gold.dim_order_status` AS os
    ON o.status = os.order_status

LEFT JOIN `prism-486509.gold.dim_date` AS dd_created
    ON DATE(o.created_at) = dd_created.date

LEFT JOIN `prism-486509.gold.dim_date` AS dd_shipped
    ON DATE(o.shipped_at) = dd_shipped.date

LEFT JOIN `prism-486509.gold.dim_date` AS dd_delivered
    ON DATE(o.delivered_at) = dd_delivered.date

LEFT JOIN `prism-486509.gold.dim_date` AS dd_returned
    ON DATE(o.returned_at) = dd_returned.date;

