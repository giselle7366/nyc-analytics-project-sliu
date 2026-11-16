{{ config(alias='dim_vehicle_type') }}

-- Group 15 | Milestone 4
-- Vehicle Type Dimension
-- Grain: one row per unique vehicle type

WITH vehicle_types AS (

    SELECT vehicle_type_1 AS vehicle_type
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE vehicle_type_1 IS NOT NULL

    UNION DISTINCT

    SELECT vehicle_type_2 AS vehicle_type
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE vehicle_type_2 IS NOT NULL

    UNION DISTINCT

    SELECT vehicle_type_3 AS vehicle_type
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE vehicle_type_3 IS NOT NULL

    UNION DISTINCT

    SELECT vehicle_type_4 AS vehicle_type
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE vehicle_type_4 IS NOT NULL

    UNION DISTINCT

    SELECT vehicle_type_5 AS vehicle_type
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE vehicle_type_5 IS NOT NULL

),

vehicle_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'vehicle_type'
        ]) }} AS vehicle_type_key,

        vehicle_type,

        CASE
            WHEN vehicle_type LIKE '%SEDAN%'
              OR vehicle_type LIKE '%PASSENGER%'
              OR vehicle_type LIKE '%STATION WAGON%'
              OR vehicle_type LIKE '%SUV%'
            THEN 'Passenger Vehicle'

            WHEN vehicle_type LIKE '%TRUCK%'
              OR vehicle_type LIKE '%TRACTOR%'
              OR vehicle_type LIKE '%VAN%'
            THEN 'Truck / Commercial'

            WHEN vehicle_type LIKE '%MOTORCYCLE%'
              OR vehicle_type LIKE '%BIKE%'
              OR vehicle_type LIKE '%SCOOTER%'
            THEN 'Two-Wheeler'

            WHEN vehicle_type LIKE '%BUS%'
            THEN 'Bus'

            ELSE 'Other'
        END AS vehicle_category

    FROM vehicle_types

)

SELECT *
FROM vehicle_dimension