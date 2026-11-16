{{ config(alias='dim_location') }}

-- Conformed location dimension shared by Traffic Signal Requests
-- and Motor Vehicle Collisions.
-- Grain: one row per unique combination of zip_code and borough.

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

    SELECT
        zip_code,
        borough
    FROM traffic_signal_locations

    UNION DISTINCT

    SELECT
        zip_code,
        borough
    FROM collision_locations

),

location_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'zip_code',
            'borough'
        ]) }} AS location_key,

        zip_code,
        borough

    FROM all_locations

),

null_placeholder AS (

    SELECT
        '-1' AS location_key,
        CAST(NULL AS STRING) AS zip_code,
        CAST(NULL AS STRING) AS borough

)

SELECT *
FROM location_dimension

UNION ALL

SELECT *
FROM null_placeholder