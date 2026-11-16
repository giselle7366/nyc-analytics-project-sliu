{{ config(alias='fact_motor_vehicle_collision') }}

-- Group 15 | Milestone 4
-- Fact: Motor Vehicle Collision
-- Grain: one row per collision

WITH collisions AS (

    SELECT *
    FROM {{ ref('stg_motor_vehicle_collisions') }}

),

joined AS (

    SELECT
        c.collision_id,

        -- Foreign keys
        COALESCE(d.date_key, -1) AS date_key,
        COALESCE(t.time_key, -1) AS time_key,
        COALESCE(l.location_key, -1) AS location_key,
        COALESCE(s.collision_severity_key, -1) AS collision_severity_key,

        -- Vehicle type foreign keys
        COALESCE(v1.vehicle_type_key, -1) AS vehicle_type_1_key,
        COALESCE(v2.vehicle_type_key, -1) AS vehicle_type_2_key,
        COALESCE(v3.vehicle_type_key, -1) AS vehicle_type_3_key,
        COALESCE(v4.vehicle_type_key, -1) AS vehicle_type_4_key,
        COALESCE(v5.vehicle_type_key, -1) AS vehicle_type_5_key,

        -- Contributing factor foreign keys
        COALESCE(f1.contributing_factor_key, -1) AS contributing_factor_1_key,
        COALESCE(f2.contributing_factor_key, -1) AS contributing_factor_2_key,
        COALESCE(f3.contributing_factor_key, -1) AS contributing_factor_3_key,
        COALESCE(f4.contributing_factor_key, -1) AS contributing_factor_4_key,
        COALESCE(f5.contributing_factor_key, -1) AS contributing_factor_5_key,

        -- Measures
        c.number_of_persons_injured,
        c.number_of_persons_killed,
        c.number_of_pedestrians_injured,
        c.number_of_pedestrians_killed,
        c.number_of_cyclist_injured,
        c.number_of_cyclist_killed,
        c.number_of_motorist_injured,
        c.number_of_motorist_killed

    FROM collisions c

    -- Date
    LEFT JOIN {{ ref('dim_date_group15') }} d
        ON c.crash_date = d.full_date

    -- Time
    LEFT JOIN {{ ref('dim_time_group15') }} t
        ON c.crash_hour = t.hour
       AND c.crash_minute = t.minute

    -- Location
    LEFT JOIN {{ ref('dim_location_group15') }} l
        ON c.zip_code = l.zip_code
       AND c.borough = l.borough

    -- Collision severity
    LEFT JOIN {{ ref('dim_collision_severity_group15') }} s
        ON (
            CASE
                WHEN c.number_of_persons_killed > 0 THEN 'Fatal'
                WHEN c.number_of_persons_injured > 0 THEN 'Injury'
                ELSE 'No Injury'
            END
        ) = s.severity_category
       AND (c.number_of_persons_injured > 0) = s.has_injury
       AND (c.number_of_persons_killed > 0) = s.has_fatality

    -- Vehicle types
    LEFT JOIN {{ ref('dim_vehicle_type_group15') }} v1
        ON c.vehicle_type_1 = v1.vehicle_type

    LEFT JOIN {{ ref('dim_vehicle_type_group15') }} v2
        ON c.vehicle_type_2 = v2.vehicle_type

    LEFT JOIN {{ ref('dim_vehicle_type_group15') }} v3
        ON c.vehicle_type_3 = v3.vehicle_type

    LEFT JOIN {{ ref('dim_vehicle_type_group15') }} v4
        ON c.vehicle_type_4 = v4.vehicle_type

    LEFT JOIN {{ ref('dim_vehicle_type_group15') }} v5
        ON c.vehicle_type_5 = v5.vehicle_type

    -- Contributing factors
    LEFT JOIN {{ ref('dim_contributing_factor_group15') }} f1
        ON c.contributing_factor_1 = f1.contributing_factor

    LEFT JOIN {{ ref('dim_contributing_factor_group15') }} f2
        ON c.contributing_factor_2 = f2.contributing_factor

    LEFT JOIN {{ ref('dim_contributing_factor_group15') }} f3
        ON c.contributing_factor_3 = f3.contributing_factor

    LEFT JOIN {{ ref('dim_contributing_factor_group15') }} f4
        ON c.contributing_factor_4 = f4.contributing_factor

    LEFT JOIN {{ ref('dim_contributing_factor_group15') }} f5
        ON c.contributing_factor_5 = f5.contributing_factor

),

final AS (

    SELECT
        ROW_NUMBER() OVER (
            ORDER BY collision_id
        ) AS collision_fact_key,

        collision_id,
        date_key,
        time_key,
        location_key,
        collision_severity_key,

        vehicle_type_1_key,
        vehicle_type_2_key,
        vehicle_type_3_key,
        vehicle_type_4_key,
        vehicle_type_5_key,

        contributing_factor_1_key,
        contributing_factor_2_key,
        contributing_factor_3_key,
        contributing_factor_4_key,
        contributing_factor_5_key,

        number_of_persons_injured,
        number_of_persons_killed,
        number_of_pedestrians_injured,
        number_of_pedestrians_killed,
        number_of_cyclist_injured,
        number_of_cyclist_killed,
        number_of_motorist_injured,
        number_of_motorist_killed

    FROM joined

)

SELECT *
FROM final