-- Clean and standardize DOB NOW job filing data
-- One row per job filing

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_nyc_dob_job_apps') }}
),

cleaned AS (
    SELECT
        -- Keep all other source columns except the ones transformed below
        * EXCEPT (
            job_filing_number,
            filing_date,
            current_status_date,
            first_permit_date,
            approved_date,
            signoff_date,
            borough,
            postcode,
            zip,
            latitude,
            longitude
        ),

        -- Identifier
        CAST(job_filing_number AS STRING) AS job_filing_number,

        -- Dates
        CAST(filing_date AS TIMESTAMP) AS filing_date,
        CAST(current_status_date AS TIMESTAMP) AS current_status_date,
        CAST(first_permit_date AS TIMESTAMP) AS first_permit_date,
        CAST(approved_date AS TIMESTAMP) AS approved_date,
        SAFE_CAST(signoff_date AS TIMESTAMP) AS signoff_date,

        -- Standardized borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        -- Standardized ZIP for conformed location dimension
        COALESCE(
            NULLIF(TRIM(CAST(postcode AS STRING)), ''),
            NULLIF(TRIM(CAST(zip AS STRING)), '')
        ) AS zip,

        -- Coordinates
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    WHERE job_filing_number IS NOT NULL
      AND filing_date IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY job_filing_number
        ORDER BY current_status_date DESC, filing_date DESC
    ) = 1
)

SELECT *
FROM cleaned