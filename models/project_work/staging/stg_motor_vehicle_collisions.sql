-- Staging model: NYC Motor Vehicle Collisions
-- Grain: one row = one collision (collision_id)
-- Cleans types, standardizes text, fills missing borough from ZIP or coordinates,
-- dedupes, and filters to 2020 to 2025.

WITH source AS (

    SELECT *
    FROM {{ source('raw', 'source_motor_vehicle_collisions') }}

),

cleaned AS (

    SELECT
        CAST(collision_id AS STRING) AS collision_id,

        -- date and time
        SAFE_CAST(SUBSTR(CAST(crash_date AS STRING), 1, 10) AS DATE) AS crash_date,
        SAFE_CAST(SPLIT(CAST(crash_time AS STRING), ':')[SAFE_OFFSET(0)] AS INT64) AS crash_hour,
        SAFE_CAST(SPLIT(CAST(crash_time AS STRING), ':')[SAFE_OFFSET(1)] AS INT64) AS crash_minute,

        -- location
        NULLIF(UPPER(TRIM(CAST(borough AS STRING))), '') AS borough,
        REGEXP_EXTRACT(CAST(zip_code AS STRING), r'^\d{5}') AS zip_code,
        SAFE_CAST(latitude AS FLOAT64) AS latitude,
        SAFE_CAST(longitude AS FLOAT64) AS longitude,

        -- measures
        COALESCE(SAFE_CAST(number_of_persons_injured AS INT64), 0) AS number_of_persons_injured,
        COALESCE(SAFE_CAST(number_of_persons_killed AS INT64), 0) AS number_of_persons_killed,
        COALESCE(SAFE_CAST(number_of_pedestrians_injured AS INT64), 0) AS number_of_pedestrians_injured,
        COALESCE(SAFE_CAST(number_of_pedestrians_killed AS INT64), 0) AS number_of_pedestrians_killed,
        COALESCE(SAFE_CAST(number_of_cyclist_injured AS INT64), 0) AS number_of_cyclist_injured,
        COALESCE(SAFE_CAST(number_of_cyclist_killed AS INT64), 0) AS number_of_cyclist_killed,
        COALESCE(SAFE_CAST(number_of_motorist_injured AS INT64), 0) AS number_of_motorist_injured,
        COALESCE(SAFE_CAST(number_of_motorist_killed AS INT64), 0) AS number_of_motorist_killed,

        -- vehicle types
        NULLIF(UPPER(TRIM(vehicle_type_code1)), '') AS vehicle_type_1,
        NULLIF(UPPER(TRIM(vehicle_type_code2)), '') AS vehicle_type_2,
        NULLIF(UPPER(TRIM(vehicle_type_code_3)), '') AS vehicle_type_3,
        NULLIF(UPPER(TRIM(vehicle_type_code_4)), '') AS vehicle_type_4,
        NULLIF(UPPER(TRIM(vehicle_type_code_5)), '') AS vehicle_type_5,

        -- contributing factors
        NULLIF(UPPER(TRIM(contributing_factor_vehicle_1)), '') AS contributing_factor_1,
        NULLIF(UPPER(TRIM(contributing_factor_vehicle_2)), '') AS contributing_factor_2,
        NULLIF(UPPER(TRIM(contributing_factor_vehicle_3)), '') AS contributing_factor_3,
        NULLIF(UPPER(TRIM(contributing_factor_vehicle_4)), '') AS contributing_factor_4,
        NULLIF(UPPER(TRIM(contributing_factor_vehicle_5)), '') AS contributing_factor_5

    FROM source

    WHERE collision_id IS NOT NULL

),

-- count collisions per ZIP and borough
zip_borough_counts AS (

    SELECT
        zip_code,
        borough,
        COUNT(*) AS n
    FROM cleaned
    WHERE zip_code IS NOT NULL
      AND borough IS NOT NULL
    GROUP BY zip_code, borough

),

-- most common borough for each NYC ZIP
zip_borough_lookup AS (

    SELECT
        zip_code,
        borough
    FROM zip_borough_counts
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY zip_code
        ORDER BY n DESC
    ) = 1

),

-- Google ZIP boundaries tagged with borough
nyc_zip_shapes AS (

    SELECT
        z.zip_code,
        z.zip_code_geom,
        l.borough
    FROM {{ source('geo_us_boundaries', 'zip_codes') }} z
    INNER JOIN zip_borough_lookup l
        ON z.zip_code = l.zip_code

),

-- fill missing borough using coordinates
coord_matches AS (

    SELECT
        c.collision_id,
        s.zip_code AS geo_zip_code,
        s.borough AS geo_borough
    FROM cleaned c
    INNER JOIN nyc_zip_shapes s
        ON ST_CONTAINS(
            s.zip_code_geom,
            ST_GEOGPOINT(c.longitude, c.latitude)
        )
    WHERE c.borough IS NULL
      AND c.latitude BETWEEN 40.4 AND 41.0
      AND c.longitude BETWEEN -74.3 AND -73.6
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY c.collision_id
        ORDER BY s.zip_code
    ) = 1

),

final AS (

    SELECT
        c.collision_id,
        c.crash_date,
        c.crash_hour,
        c.crash_minute,

        COALESCE(
            c.borough,
            z.borough,
            g.geo_borough,
            'UNKNOWN'
        ) AS borough,

        CASE
            WHEN c.borough IS NOT NULL THEN 'ORIGINAL'
            WHEN z.borough IS NOT NULL THEN 'ZIP'
            WHEN g.geo_borough IS NOT NULL THEN 'COORDINATES'
            ELSE 'UNKNOWN'
        END AS borough_source,

        COALESCE(c.zip_code, g.geo_zip_code) AS zip_code,

        c.latitude,
        c.longitude,

        c.number_of_persons_injured,
        c.number_of_persons_killed,
        c.number_of_pedestrians_injured,
        c.number_of_pedestrians_killed,
        c.number_of_cyclist_injured,
        c.number_of_cyclist_killed,
        c.number_of_motorist_injured,
        c.number_of_motorist_killed,

        c.vehicle_type_1,
        c.vehicle_type_2,
        c.vehicle_type_3,
        c.vehicle_type_4,
        c.vehicle_type_5,

        c.contributing_factor_1,
        c.contributing_factor_2,
        c.contributing_factor_3,
        c.contributing_factor_4,
        c.contributing_factor_5

    FROM cleaned c

    LEFT JOIN zip_borough_lookup z
        ON c.zip_code = z.zip_code

    LEFT JOIN coord_matches g
        ON c.collision_id = g.collision_id

    WHERE c.crash_date BETWEEN '2020-01-01' AND '2025-12-31'

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY c.collision_id
        ORDER BY c.crash_date
    ) = 1

)

SELECT *
FROM final