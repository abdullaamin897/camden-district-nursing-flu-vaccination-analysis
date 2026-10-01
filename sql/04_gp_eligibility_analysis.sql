/*
Project: Camden District Nursing Housebound Flu Vaccination Analysis
File: 04_gp_eligibility_analysis.sql

Purpose:
Compare patient validation issues across GP practices using both
absolute counts and issue rates.

All data used in this project is synthetic.
*/


-- 1. Build latest vaccination status and cohort classification

WITH latest_s1 AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY nhs_number
            ORDER BY status_recorded_date DESC
        ) AS rn

    FROM S1_Vaccination_Status

),

cohort AS (

    SELECT
        p.nhs_number,
        p.gp_practice_id,

        CASE
            WHEN p.deceased_flag = 'Yes'
                THEN 'Deceased'

            WHEN s.flu_vaccination_status = 'Vaccinated'
                THEN 'Already Vaccinated'

            WHEN p.active_dn_caseload = 'No'
                THEN 'Not Active DN Caseload'

            WHEN p.housebound_status = 'Not Housebound'
                THEN 'Not Housebound'

            WHEN p.housebound_status = 'Status Unclear'
                THEN 'Review Required'

            WHEN p.gp_confirmed_flu_eligible IS NULL
                THEN 'Review Required'

            WHEN p.gp_confirmed_flu_eligible = 'No'
                THEN 'Eligibility Not Confirmed'

            ELSE 'Validated Eligible'

        END AS cohort_status

    FROM Patient_List p

    LEFT JOIN latest_s1 s
        ON p.nhs_number = s.nhs_number
       AND s.rn = 1
)


-- 2. Compare total records and issue rates by GP practice

SELECT
    gp_practice_id,

    COUNT(*) AS total_records,

    SUM(
        CASE
            WHEN cohort_status <> 'Validated Eligible'
            THEN 1
            ELSE 0
        END
    ) AS issue_records,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN cohort_status <> 'Validated Eligible'
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        1
    ) AS issue_rate_pct

FROM cohort

GROUP BY gp_practice_id

ORDER BY issue_rate_pct DESC;

-- 3. Break down the type of validation issue by GP practice

WITH latest_s1 AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY nhs_number
            ORDER BY status_recorded_date DESC
        ) AS rn

    FROM S1_Vaccination_Status

),

cohort AS (

    SELECT
        p.nhs_number,
        p.gp_practice_id,

        CASE
            WHEN p.deceased_flag = 'Yes'
                THEN 'Deceased'

            WHEN s.flu_vaccination_status = 'Vaccinated'
                THEN 'Already Vaccinated'

            WHEN p.active_dn_caseload = 'No'
                THEN 'Not Active DN Caseload'

            WHEN p.housebound_status = 'Not Housebound'
                THEN 'Not Housebound'

            WHEN p.housebound_status = 'Status Unclear'
                THEN 'Review Required'

            WHEN p.gp_confirmed_flu_eligible IS NULL
                THEN 'Review Required'

            WHEN p.gp_confirmed_flu_eligible = 'No'
                THEN 'Eligibility Not Confirmed'

            ELSE 'Validated Eligible'

        END AS cohort_status

    FROM Patient_List p

    LEFT JOIN latest_s1 s
        ON p.nhs_number = s.nhs_number
       AND s.rn = 1
)

SELECT
    gp_practice_id,
    cohort_status,
    COUNT(*) AS patient_count

FROM cohort

GROUP BY
    gp_practice_id,
    cohort_status

ORDER BY
    gp_practice_id,
    patient_count DESC;

-- 4. Specifically compare patients not on the active DN caseload

WITH cohort AS (

    SELECT
        nhs_number,
        gp_practice_id,
        active_dn_caseload
    FROM Patient_List

)

SELECT
    gp_practice_id,

    COUNT(*) AS total_records,

    SUM(
        CASE
            WHEN active_dn_caseload = 'No'
            THEN 1
            ELSE 0
        END
    ) AS not_active_dn_records,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN active_dn_caseload = 'No'
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        1
    ) AS not_active_dn_rate_pct

FROM cohort

GROUP BY gp_practice_id

ORDER BY not_active_dn_rate_pct DESC;

/*
Interpretation Note:

A higher issue rate does not automatically prove that a GP practice
submitted poor-quality data.

The rate identifies practices where a larger proportion of records
required review or exclusion.

Further investigation should consider:

- Number of records submitted
- Type of issue
- Active District Nursing caseload alignment
- Vaccination status
- Eligibility status
- Possible differences in process or recording

Both absolute issue counts and issue rates should be reviewed together.
*/
