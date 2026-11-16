{{ config(alias='fact_traffic_signal_request') }}

-- Group 15 | Milestone 4
-- Fact: Traffic Signal Request
-- Grain: one row per traffic signal request

WITH requests AS (

    SELECT *
    FROM {{ ref('stg_traffic_signal_requests') }}

),

joined AS (

    SELECT
        r.unique_key,

        -- Date key
        COALESCE(
            SAFE_CAST(d.date_key AS INT64),
            -1
        ) AS date_key,

        -- Time key
        COALESCE(
            SAFE_CAST(t.time_key AS INT64),
            -1
        ) AS time_key,

        -- Location key
        COALESCE(
            SAFE_CAST(l.location_key AS INT64),
            -1
        ) AS location_key,

        -- Problem key
        COALESCE(
            SAFE_CAST(p.problem_key AS INT64),
            -1
        ) AS problem_key,

        -- One row represents one request
        1 AS request_count

    FROM requests r

    -- Date dimension
    LEFT JOIN {{ ref('dim_date_group15') }} d
        ON CAST(r.created_date AS DATE) = d.full_date

    -- Time dimension
    LEFT JOIN {{ ref('dim_time_group15') }} t
        ON EXTRACT(HOUR FROM r.created_date) = t.hour
       AND EXTRACT(MINUTE FROM r.created_date) = t.minute

    -- Location dimension
    LEFT JOIN {{ ref('dim_location_group15') }} l
        ON r.zip_code = l.zip_code
       AND r.borough = l.borough

    -- Problem dimension
    LEFT JOIN {{ ref('dim_problem_group15') }} p
        ON r.complaint_type = p.complaint_type
       AND r.descriptor = p.problem_component

),

final AS (

    SELECT
        ROW_NUMBER() OVER (
            ORDER BY unique_key
        ) AS request_fact_key,

        unique_key,
        date_key,
        time_key,
        location_key,
        problem_key,
        request_count

    FROM joined

)

SELECT *
FROM final