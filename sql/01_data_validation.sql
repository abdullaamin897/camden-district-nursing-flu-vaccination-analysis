/*
Project: Camden District Nursing Housebound Flu Vaccination Analysis
File: 01_data_validation.sql

Purpose:
Initial validation of the synthetic operational dataset before analysis.

All data used in this project is synthetic and contains no real patient
identifiable information.
*/


-- 1. Check total number of patient records

SELECT
    COUNT(*) AS total_patient_records
FROM Patient_List;


-- 2. Check number of unique patients

SELECT
    COUNT(DISTINCT nhs_number) AS unique_patients
FROM Patient_List;


-- 3. Identify duplicate patient records

SELECT
    nhs_number,
    COUNT(*) AS record_count
FROM Patient_List
GROUP BY nhs_number
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- 4. Check for missing GP practice IDs

SELECT
    COUNT(*) AS missing_gp_practice
FROM Patient_List
WHERE gp_practice_id IS NULL;


-- 5. Check for missing GP eligibility confirmation

SELECT
    COUNT(*) AS missing_gp_eligibility_confirmation
FROM Patient_List
WHERE gp_confirmed_flu_eligible IS NULL;


-- 6. Review housebound status values

SELECT
    housebound_status,
    COUNT(*) AS patient_count
FROM Patient_List
GROUP BY housebound_status
ORDER BY patient_count DESC;


-- 7. Review active District Nursing caseload status

SELECT
    active_dn_caseload,
    COUNT(*) AS patient_count
FROM Patient_List
GROUP BY active_dn_caseload;


-- 8. Check whether all patient GP IDs exist in the GP reference table

SELECT DISTINCT
    p.gp_practice_id
FROM Patient_List p
LEFT JOIN GP_Practices g
    ON p.gp_practice_id = g.gp_practice_id
WHERE g.gp_practice_id IS NULL;


-- 9. Identify duplicate visit IDs

SELECT
    visit_id,
    COUNT(*) AS record_count
FROM Visit_Log
GROUP BY visit_id
HAVING COUNT(*) > 1;


-- 10. Identify duplicate vaccination IDs

SELECT
    vaccination_id,
    COUNT(*) AS record_count
FROM Vaccination_Records
GROUP BY vaccination_id
HAVING COUNT(*) > 1;


-- 11. Identify the latest SystmOne vaccination status for each patient

WITH latest_s1 AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY nhs_number
            ORDER BY status_recorded_date DESC
        ) AS rn

    FROM S1_Vaccination_Status

)

SELECT *
FROM latest_s1
WHERE rn = 1;
