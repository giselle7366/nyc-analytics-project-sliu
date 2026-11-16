{{ config(alias='dim_collision_severity') }}

-- Group 15 | Milestone 4
-- Collision Severity Dimension
-- Grain: one row per severity category and injury/fatality combination

WITH collision_severity AS (

    SELECT DISTINCT
        CASE
            WHEN number_of_persons_killed > 0 THEN 'Fatal'
            WHEN number_of_persons_injured > 0 THEN 'Injury'
            ELSE 'No Injury'
        END AS severity_category,

        number_of_persons_injured > 0 AS has_injury,
        number_of_persons_killed > 0 AS has_fatality

    FROM {{ ref('stg_motor_vehicle_collisions') }}

),

numbered AS (

    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                severity_category,
                has_injury,
                has_fatality
        ) AS collision_severity_key,

        severity_category,
        has_injury,
        has_fatality

    FROM collision_severity

),

null_placeholder AS (

    SELECT
        CAST(-1 AS INT64) AS collision_severity_key,
        'Unknown' AS severity_category,
        FALSE AS has_injury,
        FALSE AS has_fatality

)

SELECT *
FROM numbered

UNION ALL

SELECT *
FROM null_placeholder