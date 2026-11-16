{{ config(alias='dim_collision_severity') }}

-- Group 15 | Milestone 4
-- Dimension: Collision Severity
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

final AS (

    SELECT
        TO_HEX(MD5(CONCAT(
            severity_category, '|',
            CAST(has_injury AS STRING), '|',
            CAST(has_fatality AS STRING)
        ))) AS collision_severity_key,

        severity_category,
        has_injury,
        has_fatality

    FROM collision_severity

)

SELECT *
FROM final