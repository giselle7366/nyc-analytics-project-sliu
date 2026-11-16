{{ config(alias='dim_problem') }}

-- Group 15 | Milestone 4
-- Problem Dimension
-- Grain: one row per unique complaint_type / problem_component
-- problem_component comes from descriptor
-- problem_condition and problem_category are derived fields

WITH distinct_problems AS (

    SELECT DISTINCT
        complaint_type,
        descriptor AS problem_component
    FROM {{ ref('stg_traffic_signal_requests') }}
    WHERE complaint_type IS NOT NULL
      AND descriptor IS NOT NULL

),

enriched AS (

    SELECT
        complaint_type,
        problem_component,

        CASE
            WHEN LOWER(problem_component) LIKE '%controller%'
              OR LOWER(problem_component) LIKE '%communication%'
            THEN 'Control System'

            WHEN LOWER(problem_component) LIKE '%lamp%'
              OR LOWER(problem_component) LIKE '%signal head%'
            THEN 'Signal Light'

            WHEN LOWER(problem_component) LIKE '%pedestrian signal%'
              OR LOWER(problem_component) LIKE '%ped multiple%'
              OR LOWER(problem_component) LIKE '%aps%'
            THEN 'Pedestrian Signal'

            WHEN LOWER(problem_component) LIKE '%door%'
              OR LOWER(problem_component) LIKE '%cabinet%'
              OR LOWER(problem_component) LIKE '%base%'
            THEN 'Signal Equipment'

            ELSE 'Other'
        END AS problem_condition,

        CASE
            WHEN LOWER(problem_component) LIKE '%pedestrian%'
              OR LOWER(problem_component) LIKE '%ped multiple%'
              OR LOWER(problem_component) LIKE '%aps%'
            THEN 'Pedestrian'

            WHEN LOWER(problem_component) LIKE '%veh%'
              OR LOWER(problem_component) LIKE '%signal head%'
              OR LOWER(problem_component) LIKE '%lamp%'
            THEN 'Vehicle Signal'

            WHEN LOWER(problem_component) LIKE '%controller%'
              OR LOWER(problem_component) LIKE '%communication%'
            THEN 'Control Equipment'

            WHEN LOWER(problem_component) LIKE '%door%'
              OR LOWER(problem_component) LIKE '%cabinet%'
              OR LOWER(problem_component) LIKE '%base%'
            THEN 'Physical Equipment'

            ELSE 'Other'
        END AS problem_category

    FROM distinct_problems

),

problem_dimension AS (

    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                complaint_type,
                problem_component,
                problem_condition,
                problem_category
        ) AS problem_key,

        complaint_type,
        problem_component,
        problem_condition,
        problem_category

    FROM enriched

),

null_placeholder AS (

    SELECT
        CAST(-1 AS INT64) AS problem_key,
        CAST(NULL AS STRING) AS complaint_type,
        CAST(NULL AS STRING) AS problem_component,
        CAST(NULL AS STRING) AS problem_condition,
        CAST(NULL AS STRING) AS problem_category

)

SELECT *
FROM problem_dimension

UNION ALL

SELECT *
FROM null_placeholder