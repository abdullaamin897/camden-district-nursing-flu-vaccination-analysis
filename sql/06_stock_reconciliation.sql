/*
Project: Camden District Nursing Housebound Flu Vaccination Analysis
File: 06_stock_reconciliation.sql

Purpose:
Summarise vaccine stock transactions, calculate utilisation and wastage,
and identify reconciliation discrepancies.

All data used in this project is synthetic.
*/


-- 1. Summarise stock transactions by GP practice and batch

SELECT
    gp_practice_id,
    batch_number,

    SUM(
        CASE
            WHEN transaction_type = 'Received'
            THEN quantity
            ELSE 0
        END
    ) AS received,

    SUM(
        CASE
            WHEN transaction_type = 'Administered'
            THEN quantity
            ELSE 0
        END
    ) AS administered,

    SUM(
        CASE
            WHEN transaction_type = 'Wasted'
            THEN quantity
            ELSE 0
        END
    ) AS wasted,

    SUM(
        CASE
            WHEN transaction_type = 'Closing Balance'
            THEN quantity
            ELSE 0
        END
    ) AS closing_balance

FROM Stock_Log

GROUP BY
    gp_practice_id,
    batch_number

ORDER BY
    gp_practice_id,
    batch_number;

-- 2. Calculate stock utilisation and wastage rates

WITH stock_summary AS (

    SELECT
        gp_practice_id,
        batch_number,

        SUM(
            CASE
                WHEN transaction_type = 'Received'
                THEN quantity
                ELSE 0
            END
        ) AS received,

        SUM(
            CASE
                WHEN transaction_type = 'Administered'
                THEN quantity
                ELSE 0
            END
        ) AS administered,

        SUM(
            CASE
                WHEN transaction_type = 'Wasted'
                THEN quantity
                ELSE 0
            END
        ) AS wasted,

        SUM(
            CASE
                WHEN transaction_type = 'Closing Balance'
                THEN quantity
                ELSE 0
            END
        ) AS closing_balance

    FROM Stock_Log

    GROUP BY
        gp_practice_id,
        batch_number

)

SELECT
    gp_practice_id,
    batch_number,
    received,
    administered,
    wasted,
    closing_balance,

    ROUND(
        100.0 * administered
        / NULLIF(received, 0),
        1
    ) AS stock_utilisation_pct,

    ROUND(
        100.0 * wasted
        / NULLIF(received, 0),
        1
    ) AS wastage_pct

FROM stock_summary

ORDER BY wastage_pct DESC;

-- 3. Check whether stock balances reconcile

WITH stock_summary AS (

    SELECT
        gp_practice_id,
        batch_number,

        SUM(
            CASE
                WHEN transaction_type = 'Received'
                THEN quantity
                ELSE 0
            END
        ) AS received,

        SUM(
            CASE
                WHEN transaction_type = 'Administered'
                THEN quantity
                ELSE 0
            END
        ) AS administered,

        SUM(
            CASE
                WHEN transaction_type = 'Wasted'
                THEN quantity
                ELSE 0
            END
        ) AS wasted,

        SUM(
            CASE
                WHEN transaction_type = 'Closing Balance'
                THEN quantity
                ELSE 0
            END
        ) AS closing_balance

    FROM Stock_Log

    GROUP BY
        gp_practice_id,
        batch_number

)

SELECT
    gp_practice_id,
    batch_number,
    received,
    administered,
    wasted,
    closing_balance,

    received
      - administered
      - wasted
      - closing_balance
        AS reconciliation_difference,

    CASE
        WHEN received = administered + wasted + closing_balance
            THEN 'Reconciled'
        ELSE 'Investigate'
    END AS reconciliation_status

FROM stock_summary;

-- 4. Compare stock recorded as administered with vaccination records

WITH stock_administered AS (

    SELECT
        batch_number,

        SUM(
            CASE
                WHEN transaction_type = 'Administered'
                THEN quantity
                ELSE 0
            END
        ) AS stock_administered

    FROM Stock_Log

    GROUP BY batch_number

),

vaccination_count AS (

    SELECT
        batch_number,
        COUNT(*) AS recorded_vaccinations

    FROM Vaccination_Records

    GROUP BY batch_number

)

SELECT
    s.batch_number,
    s.stock_administered,
    COALESCE(v.recorded_vaccinations, 0) AS recorded_vaccinations,

    s.stock_administered
        - COALESCE(v.recorded_vaccinations, 0)
        AS vaccination_record_difference

FROM stock_administered s

LEFT JOIN vaccination_count v
    ON s.batch_number = v.batch_number

ORDER BY vaccination_record_difference DESC;

/*
Interpretation Note:

A stock discrepancy should not automatically be described as vaccine loss.

Possible causes may include:

- Delayed or incomplete vaccination recording
- Incorrect batch number recording
- Stock transaction entry errors
- Differences in reporting cut-off dates
- Doses being used for patients linked to another GP practice
- Other reconciliation or data-quality issues

The discrepancy should therefore be investigated before a conclusion is made.
*/
