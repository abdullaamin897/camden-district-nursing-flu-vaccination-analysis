/*
Project: Camden District Nursing Housebound Flu Vaccination Analysis
File: 03_contact_pathway.sql

Purpose:
Analyse patient contact activity, repeated contact attempts, latest contact
outcome and historical Unable To Contact (UTC) activity.

All data used in this project is synthetic.
*/


-- 1. Summarise contact activity to one row per patient

WITH contact_summary AS (

    SELECT
        nhs_number,
        COUNT(*) AS contact_attempts,
        COUNT(DISTINCT contact_date) AS contact_days,

        COUNT(
            DISTINCT CASE
                WHEN contact_outcome = 'No Answer'
                THEN contact_date
            END
        ) AS no_answer_days,

        SUM(
            CASE
                WHEN contact_outcome = 'Answered'
                THEN 1
                ELSE 0
            END
        ) AS answered_contacts,

        MAX(
            CASE
                WHEN consent_status = 'Consented'
                THEN 1
                ELSE 0
            END
        ) AS ever_consented,

        MAX(
            CASE
                WHEN already_vaccinated_reported = 'Yes'
                THEN 1
                ELSE 0
            END
        ) AS vaccination_reported_during_contact

    FROM Contact_Log

    GROUP BY nhs_number

)

SELECT *
FROM contact_summary;

-- 2. Identify the latest contact record for each patient

WITH latest_contact AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY nhs_number
            ORDER BY contact_date DESC, attempt_number DESC
        ) AS rn

    FROM Contact_Log

)

SELECT
    nhs_number,
    contact_date AS latest_contact_date,
    contact_outcome AS latest_contact_outcome,
    consent_status AS latest_consent_status,
    already_vaccinated_reported
FROM latest_contact
WHERE rn = 1;

-- 3. Combine contact history with the latest patient contact status

WITH contact_summary AS (

    SELECT
        nhs_number,
        COUNT(*) AS contact_attempts,
        COUNT(DISTINCT contact_date) AS contact_days,

        COUNT(
            DISTINCT CASE
                WHEN contact_outcome = 'No Answer'
                THEN contact_date
            END
        ) AS no_answer_days

    FROM Contact_Log

    GROUP BY nhs_number

),

latest_contact AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY nhs_number
            ORDER BY contact_date DESC, attempt_number DESC
        ) AS rn

    FROM Contact_Log

)

SELECT
    p.nhs_number,

    COALESCE(c.contact_attempts, 0) AS contact_attempts,
    COALESCE(c.contact_days, 0) AS contact_days,

    l.contact_date AS latest_contact_date,
    l.contact_outcome AS latest_contact_outcome,
    l.consent_status AS latest_consent_status,

    CASE
        WHEN COALESCE(c.no_answer_days, 0) >= 3
            THEN 'Yes'
        ELSE 'No'
    END AS previously_utc

FROM Patient_List p

LEFT JOIN contact_summary c
    ON p.nhs_number = c.nhs_number

LEFT JOIN latest_contact l
    ON p.nhs_number = l.nhs_number
   AND l.rn = 1;

/*
Business Rule:

Three unsuccessful contact days can result in a patient being recorded as
Unable To Contact (UTC).

UTC is retained as historical information rather than automatically being
treated as the patient's final pathway status.

If the patient is successfully contacted later, the latest contact outcome
takes priority while the historical UTC flag remains available for workload
and pathway analysis.

Multiple calls made on the same day do not count as three separate contact
days.
*/
