{{ config(alias='dim_time') }}

-- Group 15 | Milestone 4
-- Shared Time Dimension
-- Grain: one row per unique hour/minute combination

WITH collision_times AS (

    SELECT DISTINCT
        crash_hour AS hour,
        crash_minute AS minute
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE crash_hour IS NOT NULL
      AND crash_minute IS NOT NULL

),

traffic_signal_times AS (

    SELECT DISTINCT
        EXTRACT(HOUR FROM created_date) AS hour,
        EXTRACT(MINUTE FROM created_date) AS minute
    FROM {{ ref('stg_traffic_signal_requests') }}
    WHERE created_date IS NOT NULL

),

all_times AS (

    SELECT hour, minute
    FROM collision_times

    UNION DISTINCT

    SELECT hour, minute
    FROM traffic_signal_times

),

time_dimension AS (

    SELECT
        (hour * 100) + minute AS time_key,
        hour,
        minute,

        CASE
            WHEN hour >= 5 AND hour < 12 THEN 'Morning'
            WHEN hour >= 12 AND hour < 17 THEN 'Afternoon'
            WHEN hour >= 17 AND hour < 21 THEN 'Evening'
            ELSE 'Night'
        END AS time_of_day

    FROM all_times

)

SELECT *
FROM time_dimension