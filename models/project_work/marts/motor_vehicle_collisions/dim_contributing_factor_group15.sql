{{ config(alias='dim_contributing_factor') }}

-- Group 15 | Milestone 4
-- Contributing Factor Dimension
-- Grain: one row per unique contributing factor

WITH contributing_factors AS (

    SELECT contributing_factor_1 AS contributing_factor
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE contributing_factor_1 IS NOT NULL

    UNION DISTINCT

    SELECT contributing_factor_2 AS contributing_factor
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE contributing_factor_2 IS NOT NULL

    UNION DISTINCT

    SELECT contributing_factor_3 AS contributing_factor
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE contributing_factor_3 IS NOT NULL

    UNION DISTINCT

    SELECT contributing_factor_4 AS contributing_factor
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE contributing_factor_4 IS NOT NULL

    UNION DISTINCT

    SELECT contributing_factor_5 AS contributing_factor
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE contributing_factor_5 IS NOT NULL

),

factor_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'contributing_factor'
        ]) }} AS contributing_factor_key,

        contributing_factor,

        CASE
            WHEN contributing_factor LIKE '%DRIVER INATTENTION%'
              OR contributing_factor LIKE '%DISTRACTION%'
              OR contributing_factor LIKE '%CELL PHONE%'
            THEN 'Driver Attention'

            WHEN contributing_factor LIKE '%FAILURE TO YIELD%'
              OR contributing_factor LIKE '%RIGHT-OF-WAY%'
              OR contributing_factor LIKE '%TRAFFIC CONTROL%'
            THEN 'Traffic Rule'

            WHEN contributing_factor LIKE '%UNSAFE SPEED%'
              OR contributing_factor LIKE '%SPEEDING%'
              OR contributing_factor LIKE '%FOLLOWING TOO CLOSELY%'
            THEN 'Driving Behavior'

            WHEN contributing_factor LIKE '%ALCOHOL%'
              OR contributing_factor LIKE '%DRUG%'
              OR contributing_factor LIKE '%ILLNESS%'
              OR contributing_factor LIKE '%FATIGUE%'
            THEN 'Driver Condition'

            WHEN contributing_factor LIKE '%PAVEMENT%'
              OR contributing_factor LIKE '%ROADWAY%'
              OR contributing_factor LIKE '%WEATHER%'
              OR contributing_factor LIKE '%GLARE%'
            THEN 'Road / Environment'

            WHEN contributing_factor LIKE '%VEHICLE%'
              OR contributing_factor LIKE '%DEFECT%'
            THEN 'Vehicle Related'

            ELSE 'Other'
        END AS factor_category

    FROM contributing_factors

)

SELECT *
FROM factor_dimension