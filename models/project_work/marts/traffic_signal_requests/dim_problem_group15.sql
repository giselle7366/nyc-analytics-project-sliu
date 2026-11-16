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

        -- Derived problem condition
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

        -- Derived broader category
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
        {{ dbt_utils.generate_surrogate_key([
            'complaint_type',
            'problem_component',
            'problem_condition',
            'problem_category'
        ]) }} AS problem_key,

        complaint_type,
        problem_component,
        problem_condition,
        problem_category

    FROM enriched

)

SELECT *
FROM problem_dimension