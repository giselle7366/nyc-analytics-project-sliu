{{ config(alias='dim_date') }}

-- Group 15 | Milestone 4
-- Shared Date Dimension
-- Grain: one row per calendar date

WITH dates AS (

    SELECT DISTINCT
        CAST(crash_date AS DATE) AS full_date
    FROM {{ ref('stg_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT DISTINCT
        CAST(created_date AS DATE) AS full_date
    FROM {{ ref('stg_traffic_signal_requests') }}

),

date_attributes AS (

    SELECT
        CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64) AS date_key,
        full_date,
        EXTRACT(YEAR FROM full_date) AS year,
        EXTRACT(QUARTER FROM full_date) AS quarter,
        EXTRACT(MONTH FROM full_date) AS month,
        EXTRACT(DAY FROM full_date) AS day,
        FORMAT_DATE('%A', full_date) AS day_of_week,
        EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7) AS is_weekend,

        CASE
            WHEN EXTRACT(MONTH FROM full_date) IN (12, 1, 2) THEN 'Winter'
            WHEN EXTRACT(MONTH FROM full_date) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM full_date) IN (6, 7, 8) THEN 'Summer'
            ELSE 'Fall'
        END AS season

    FROM dates

    WHERE full_date BETWEEN DATE '2020-01-01'
                        AND DATE '2025-12-31'

)

SELECT *
FROM date_attributes