SELECT
    order_id,
    user_id,
    status,
    CAST(gender AS STRING) AS gender,
    -- Convert created_at from STRING to TIMESTAMP and format
    FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP(created_at)) AS created_at,
    
    -- Handle other timestamp columns, allow NULLs
    CASE 
        WHEN returned_at IS NOT NULL THEN FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP(returned_at))
        ELSE NULL
    END AS returned_at,
    
    CASE 
        WHEN shipped_at IS NOT NULL THEN FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP(shipped_at))
        ELSE NULL
    END AS shipped_at,
    
    CASE 
        WHEN delivered_at IS NOT NULL THEN FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP(delivered_at))
        ELSE NULL
    END AS delivered_at,
    
    num_of_item

FROM `bronze.ext_orders`;
