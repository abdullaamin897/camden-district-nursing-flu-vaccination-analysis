/*
Project: Camden District Nursing Housebound Flu Vaccination Analysis
File: 02_eligible_cohort.sql

Purpose:
Create a validated patient cohort using the latest available vaccination
status and operational eligibility rules.

All data used in this project is synthetic.
*/


-- 1. Identify the latest SystmOne vaccination status per patient

WITH latest_s1 AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY nhs_number
            ORDER BY status_recorded_date DESC
        ) AS rn
    FROM S1_Vaccination_Status

),

-- 2. Join the latest status to the patient list

patient_status AS (

    SELECT
        p.patient_record_id,
        p.nhs_number,
        p.gp_practice_id,
        p.neighbourhood_reported,
        p.sub_team_reported,
        p.active_dn_caseload,
        p.housebound_status,
        p.gp_confirmed_flu_eligible,
        p.deceased_flag,
        p.immunosuppressed_flag,

        s.flu_vaccination_status,
        s.vaccination_date,
        s.provider_type,
        s.status_recorded_date

    FROM Patient_List p

    LEFT JOIN latest_s1 s
        ON p.nhs_number = s.nhs_number
       AND s.rn = 1

),

-- 3. Classify each patient into a cohort status

cohort AS (

    SELECT
        *,

        CASE

            WHEN deceased_flag = 'Yes'
                THEN 'Deceased'

            WHEN flu_vaccination_status = 'Vaccinated'
                THEN 'Already Vaccinated'

            WHEN active_dn_caseload = 'No'
                THEN 'Not Active DN Caseload'

            WHEN housebound_status = 'Not Housebound'
                THEN 'Not Housebound'

            WHEN housebound_status = 'Status Unclear'
                THEN 'Review Required'

            WHEN gp_confirmed_flu_eligible IS NULL
                THEN 'Review Required'

            WHEN gp_confirmed_flu_eligible = 'No'
                THEN 'Eligibility Not Confirmed'

            ELSE 'Validated Eligible'

        END AS cohort_status

    FROM patient_status

)

SELECT *
FROM cohort;

-- 4. Summarise patient cohort

WITH latest_s1 AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY nhs_number
            ORDER BY status_recorded_date DESC
        ) AS rn
    FROM S1_Vaccination_Status

),

patient_status AS (

    SELECT
        p.*,
        s.flu_vaccination_status

    FROM Patient_List p

    LEFT JOIN latest_s1 s
        ON p.nhs_number = s.nhs_number
       AND s.rn = 1

),

cohort AS (

    SELECT
        *,

        CASE
            WHEN deceased_flag = 'Yes'
                THEN 'Deceased'

            WHEN flu_vaccination_status = 'Vaccinated'
                THEN 'Already Vaccinated'

            WHEN active_dn_caseload = 'No'
                THEN 'Not Active DN Caseload'

            WHEN housebound_status = 'Not Housebound'
                THEN 'Not Housebound'

            WHEN housebound_status = 'Status Unclear'
                THEN 'Review Required'

            WHEN gp_confirmed_flu_eligible IS NULL
                THEN 'Review Required'

            WHEN gp_confirmed_flu_eligible = 'No'
                THEN 'Eligibility Not Confirmed'

            ELSE 'Validated Eligible'
        END AS cohort_status

    FROM patient_status

)

SELECT
    cohort_status,
    COUNT(*) AS patient_count
FROM cohort
GROUP BY cohort_status
ORDER BY patient_count DESC;
