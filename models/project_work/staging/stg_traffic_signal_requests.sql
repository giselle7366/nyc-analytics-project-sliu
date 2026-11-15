WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_traffic_signal_requests') }}
),

cleaned AS (
    SELECT
        -- Keep the request identifier aligned with the dimensional model
        CAST(unique_key AS STRING) AS unique_key,

        -- Keep timestamp for later date/time dimensions
        CAST(created_date AS TIMESTAMP) AS created_date,

        -- Fields used for dim_problem
        CAST(complaint_type AS STRING) AS complaint_type,
        CAST(descriptor AS STRING) AS descriptor,

        -- Standardize ZIP field name to match dim_location
        CASE
            WHEN UPPER(TRIM(incident_zip)) IN ('N/A', 'NA') THEN NULL
            WHEN UPPER(TRIM(incident_zip)) = 'ANONYMOUS' THEN NULL
            WHEN LENGTH(TRIM(incident_zip)) = 5 THEN TRIM(incident_zip)
            WHEN LENGTH(TRIM(incident_zip)) = 9 THEN TRIM(incident_zip)
            WHEN LENGTH(TRIM(incident_zip)) = 10
                 AND SUBSTR(TRIM(incident_zip), 6, 1) = '-'
            THEN TRIM(incident_zip)
            ELSE NULL
        END AS zip_code,

        -- Standardize borough values
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    WHERE unique_key IS NOT NULL
      AND created_date IS NOT NULL
      AND borough IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY unique_key
        ORDER BY created_date DESC
    ) = 1
)

SELECT *
FROM cleaned