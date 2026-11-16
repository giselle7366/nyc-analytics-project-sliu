{{ config(alias='dim_location') }}

-- Group 15 | Milestone 4
-- Shared Location Dimension
-- Grain: one row per unique zip_code / borough combination

WITH traffic_signal_locations AS (

    SELECT DISTINCT
        zip_code,
        borough
    FROM {{ ref('stg_traffic_signal_requests') }}
    WHERE zip_code IS NOT NULL
       OR borough IS NOT NULL

),

collision_locations AS (

    SELECT DISTINCT
        zip_code,
        borough
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE zip_code IS NOT NULL
       OR borough IS NOT NULL

),

all_locations AS (

    SELECT zip_code, borough
    FROM traffic_signal_locations

    UNION DISTINCT

    SELECT zip_code, borough
    FROM collision_locations

),

numbered AS (

    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                COALESCE(zip_code, ''),
                COALESCE(borough, '')
        ) AS location_key,

        zip_code,
        borough

    FROM all_locations

),

null_placeholder AS (

    SELECT
        CAST(-1 AS INT64) AS location_key,
        CAST(NULL AS STRING) AS zip_code,
        CAST(NULL AS STRING) AS borough

)

SELECT *
FROM numbered

UNION ALL

SELECT *
FROM null_placeholder