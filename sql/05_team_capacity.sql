/*
Project: Camden District Nursing Housebound Flu Vaccination Analysis
File: 05_team_capacity.sql

Purpose:
Compare vaccination activity, visit workload and travel burden across
District Nursing sub-teams while accounting for vaccination-trained WTE.

All data used in this project is synthetic.
*/


-- 1. Calculate vaccination-trained WTE by sub-team

SELECT
    sub_team,

    SUM(
        CASE
            WHEN vaccination_trained = 'Yes'
            THEN wte
            ELSE 0
        END
    ) AS vaccination_trained_wte

FROM Staff

GROUP BY sub_team

ORDER BY sub_team;

-- 2. Aggregate visit activity to staff level before joining to Staff

WITH visit_activity AS (

    SELECT
        allocated_staff_id,

        COUNT(*) AS visit_attempts,

        SUM(
            CASE
                WHEN visit_outcome = 'Vaccinated'
                THEN 1
                ELSE 0
            END
        ) AS successful_vaccination_visits,

        SUM(travel_time_minutes) AS total_travel_minutes

    FROM Visit_Log

    GROUP BY allocated_staff_id

)

SELECT
    s.staff_id,
    s.sub_team,
    s.role,
    s.band,
    s.wte,
    s.vaccination_trained,

    COALESCE(v.visit_attempts, 0) AS visit_attempts,
    COALESCE(v.successful_vaccination_visits, 0) AS successful_vaccination_visits,
    COALESCE(v.total_travel_minutes, 0) AS total_travel_minutes

FROM Staff s

LEFT JOIN visit_activity v
    ON s.staff_id = v.allocated_staff_id

ORDER BY
    s.sub_team,
    s.staff_id;

-- 3. Count vaccinations administered by each staff member

SELECT
    administered_by_staff_id,
    COUNT(*) AS vaccinations_administered

FROM Vaccination_Records

GROUP BY administered_by_staff_id

ORDER BY vaccinations_administered DESC;

-- 4. Build team-level workload and capacity measures

WITH staff_capacity AS (

    SELECT
        sub_team,

        SUM(
            CASE
                WHEN vaccination_trained = 'Yes'
                THEN wte
                ELSE 0
            END
        ) AS vaccination_trained_wte

    FROM Staff

    GROUP BY sub_team

),

visit_activity AS (

    SELECT
        sub_team,
        COUNT(*) AS visit_attempts,

        SUM(
            CASE
                WHEN visit_outcome = 'Vaccinated'
                THEN 1
                ELSE 0
            END
        ) AS successful_vaccination_visits,

        SUM(travel_time_minutes) AS total_travel_minutes

    FROM Visit_Log

    GROUP BY sub_team

),

vaccination_activity AS (

    SELECT
        s.sub_team,
        COUNT(*) AS vaccinations_administered

    FROM Vaccination_Records v

    LEFT JOIN Staff s
        ON v.administered_by_staff_id = s.staff_id

    GROUP BY s.sub_team

)

SELECT
    c.sub_team,
    c.vaccination_trained_wte,

    COALESCE(v.visit_attempts, 0) AS visit_attempts,
    COALESCE(v.total_travel_minutes, 0) AS total_travel_minutes,
    COALESCE(a.vaccinations_administered, 0) AS vaccinations_administered,

    ROUND(
        1.0 * COALESCE(a.vaccinations_administered, 0)
        / NULLIF(c.vaccination_trained_wte, 0),
        1
    ) AS vaccinations_per_trained_wte,

    ROUND(
        1.0 * COALESCE(v.visit_attempts, 0)
        / NULLIF(c.vaccination_trained_wte, 0),
        1
    ) AS visits_per_trained_wte,

    ROUND(
        1.0 * COALESCE(v.total_travel_minutes, 0)
        / NULLIF(c.vaccination_trained_wte, 0),
        1
    ) AS travel_minutes_per_trained_wte

FROM staff_capacity c

LEFT JOIN visit_activity v
    ON c.sub_team = v.sub_team

LEFT JOIN vaccination_activity a
    ON c.sub_team = a.sub_team

ORDER BY vaccinations_per_trained_wte DESC;

/*
Interpretation Note:

Vaccinations per trained WTE is a capacity-adjusted activity measure,
not a complete measure of staff productivity or team efficiency.

Higher vaccination activity should be interpreted alongside:

- Visit attempts
- Travel burden
- Patient complexity
- Geography
- Wider District Nursing workload
- Staff role and skill mix

A team with higher vaccinations per WTE should therefore not
automatically be described as more efficient.

Event tables are aggregated before they are combined to avoid
duplicate counting caused by joining multiple many-side tables directly.
*/
