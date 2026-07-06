USE memory.default;

-- Hypothesis:
--   Payments begin at the end of the current month.
--   For each invoice, the number of monthly payments equals the number of full calendar months between now and the invoice due date.
--   Each monthly contribution is invoice_ammount / num_payments (uniform split).
--   The LAST payment per invoice absorbs any rounding remainder so that the sum of payments equals invoice_ammount exactly (balance closes to 0.00).
--   Suppliers with multiple invoices receive ONE combined payment per month.

WITH
-- Step 1: per invoice, compute how many monthly payments are needed
invoice_schedule AS (
    SELECT
        supplier_id,
        invoice_ammount,
        due_date,
        date_diff(
            'month',
            date_trunc('month', current_date),
            date_trunc('month', due_date)
        )                                                          AS num_payments
    FROM INVOICE
),

-- Step 2: expand each invoice into one row per payment, computing the per-payment amount.
payment_series AS (
    SELECT
        s.supplier_id,
        s.invoice_ammount,
        s.num_payments,
        k,
        CASE
            WHEN k = s.num_payments
                -- Last payment: residual to ensure exact closure
                THEN s.invoice_ammount
                     - CAST((s.num_payments - 1) AS DECIMAL(10, 4))
                       * ROUND(
                             CAST(s.invoice_ammount AS DECIMAL(10, 4))
                             / CAST(s.num_payments  AS DECIMAL(10, 4)),
                             2
                         )
            ELSE
                ROUND(
                    CAST(s.invoice_ammount AS DECIMAL(10, 4))
                    / CAST(s.num_payments  AS DECIMAL(10, 4)),
                    2
                )
        END                                                        AS actual_payment,
        date_add('day', -1,
            date_add('month', k,
                date_trunc('month', current_date)
            )
        )                                                          AS payment_date
    FROM invoice_schedule s
    CROSS JOIN UNNEST(sequence(1, s.num_payments)) AS t(k)
),

-- Step 3: combine all invoice contributions into one payment per (supplier, month)
monthly_payments AS (
    SELECT
        supplier_id,
        payment_date,
        CAST(SUM(actual_payment) AS DECIMAL(8, 2))                 AS payment_amount
    FROM payment_series
    GROUP BY supplier_id, payment_date
),

-- Step 4: total outstanding balance per supplier
supplier_total AS (
    SELECT
        supplier_id,
        CAST(SUM(invoice_ammount) AS DECIMAL(8, 2))                AS total_balance
    FROM INVOICE
    GROUP BY supplier_id
)

-- Final: join with SUPPLIER name and compute running balance_outstanding
SELECT
    mp.supplier_id,
    s.name                                                          AS supplier_name,
    mp.payment_amount,
    CAST(
        st.total_balance
        - SUM(mp.payment_amount) OVER (
            PARTITION BY mp.supplier_id
            ORDER BY     mp.payment_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          )
    AS DECIMAL(8, 2))                                               AS balance_outstanding,
    mp.payment_date
FROM       monthly_payments  mp
JOIN       SUPPLIER          s  ON mp.supplier_id = s.supplier_id
JOIN       supplier_total    st ON mp.supplier_id = st.supplier_id
ORDER BY   mp.supplier_id, mp.payment_date;
