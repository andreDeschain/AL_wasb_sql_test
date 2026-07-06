USE memory.default;

-- ============================================================
-- SExI: Data and Query Validation Tests
--
-- Each statement returns two columns:
--   test_name VARCHAR  -- description of what is being tested
--   result    VARCHAR  -- 'PASS' or 'FAIL'
--
-- Run AFTER all create_*.sql files have been executed.
-- ============================================================


-- T01: EMPLOYEE table has exactly 9 rows
SELECT 'T01: EMPLOYEE row count = 9'                        AS test_name,
       CASE WHEN COUNT(*) = 9 THEN 'PASS' ELSE 'FAIL' END  AS result
FROM   EMPLOYEE;


-- T02: EXPENSE table has exactly 7 rows (one per receipt file)
SELECT 'T02: EXPENSE row count = 7'                         AS test_name,
       CASE WHEN COUNT(*) = 7 THEN 'PASS' ELSE 'FAIL' END  AS result
FROM   EXPENSE;


-- T03: INVOICE table has exactly 6 rows (one per invoice file)
SELECT 'T03: INVOICE row count = 6'                         AS test_name,
       CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END  AS result
FROM   INVOICE;


-- T04: SUPPLIER table has exactly 5 rows
SELECT 'T04: SUPPLIER row count = 5'                        AS test_name,
       CASE WHEN COUNT(*) = 5 THEN 'PASS' ELSE 'FAIL' END  AS result
FROM   SUPPLIER;


-- T05: Ian James is CEO with employee_id = 1
SELECT 'T05: Ian James is CEO (employee_id = 1)'            AS test_name,
       CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END  AS result
FROM   EMPLOYEE
WHERE  employee_id = 1
  AND  first_name  = 'Ian'
  AND  last_name   = 'James'
  AND  job_title   = 'CEO';


-- T06: Supplier IDs are assigned in strict alphabetical order by company name
SELECT 'T06: Supplier IDs assigned alphabetically'          AS test_name,
       CASE WHEN COUNT(*) = 5 THEN 'PASS' ELSE 'FAIL' END  AS result
FROM (
    VALUES
        (TINYINT '1', 'Catering Plus'),
        (TINYINT '2', 'Dave''s Discos'),
        (TINYINT '3', 'Entertainment tonight'),
        (TINYINT '4', 'Ice Ice Baby'),
        (TINYINT '5', 'Party Animals')
) AS expected (supplier_id, name)
JOIN SUPPLIER
  ON SUPPLIER.supplier_id = expected.supplier_id
 AND SUPPLIER.name        = expected.name;


-- T07: Every invoice due_date falls on the last day of its month
--      (no rows should appear in the WHERE clause if all dates are correct)
SELECT 'T07: All invoice due_dates are last day of month'   AS test_name,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END  AS result
FROM   INVOICE
WHERE  due_date <> date_add('day', -1,
                       date_add('month', 1,
                           date_trunc('month', due_date)));


-- T08: Alex Jacobson (employee_id = 3) total expenses = 1682.00
--      (6.50*14 + 11.00*20 + 22.00*18 + 13.00*75 = 91 + 220 + 396 + 975)
SELECT 'T08: Alex Jacobson total expenses = 1682.00'        AS test_name,
       CASE
           WHEN CAST(SUM(unit_price * quantity) AS DECIMAL(10, 2)) = DECIMAL '1682.00'
           THEN 'PASS' ELSE 'FAIL'
       END                                                  AS result
FROM   EXPENSE
WHERE  employee_id = 3;


-- T09: calculate_largest_expensors returns exactly 1 row: Alex Jacobson, 1682.00
SELECT 'T09: Largest expensors — only Alex, 1682.00'        AS test_name,
       CASE
           WHEN COUNT(*)            = 1
            AND MIN(employee_id)    = 3
            AND MIN(total_expensed) = DECIMAL '1682.00'
           THEN 'PASS' ELSE 'FAIL'
       END                                                  AS result
FROM (
    SELECT
        e.employee_id,
        CAST(SUM(ex.unit_price * ex.quantity) AS DECIMAL(10, 2)) AS total_expensed
    FROM   EMPLOYEE  e
    JOIN   EXPENSE   ex ON e.employee_id = ex.employee_id
    GROUP  BY e.employee_id
    HAVING SUM(ex.unit_price * ex.quantity) > 1000
) top_expensors;


-- T10: Manager cycle detection returns exactly 3 employees: {1, 2, 4}
--      (Ian -> Darren -> Umberto -> Ian)
SELECT 'T10: Cycle detection finds employees {1, 2, 4}'     AS test_name,
       CASE
           WHEN COUNT(*)        = 3
            AND SUM(employee_id) = 7  -- 1 + 2 + 4 = 7
           THEN 'PASS' ELSE 'FAIL'
       END                                                  AS result
FROM (
    WITH RECURSIVE manager_chain(start_id, current_id, path, visited) AS (
        SELECT
            employee_id                                                                 AS start_id,
            manager_id                                                                  AS current_id,
            CAST(employee_id AS VARCHAR) || ' -> ' || CAST(manager_id AS VARCHAR)      AS path,
            ARRAY[employee_id]                                                          AS visited
        FROM EMPLOYEE
        WHERE manager_id IS NOT NULL
        UNION ALL
        SELECT
            mc.start_id,
            e.manager_id,
            mc.path || ' -> ' || CAST(e.manager_id AS VARCHAR),
            mc.visited || ARRAY[mc.current_id]
        FROM manager_chain mc
        JOIN EMPLOYEE e ON mc.current_id = e.employee_id
        WHERE e.manager_id IS NOT NULL
          AND mc.current_id <> mc.start_id
          AND NOT contains(mc.visited, mc.current_id)
    )
    SELECT start_id AS employee_id
    FROM   manager_chain
    WHERE  current_id = start_id
) cycle_results;


-- T11: Catering Plus (supplier_id = 1) payment plan matches README example:
--      3 payments summing to 3500.00, with amounts 1500.00, 1500.00, 500.00
SELECT 'T11: Catering Plus plan [1500, 1500, 500]'          AS test_name,
       CASE
           WHEN COUNT(*)            = 3
            AND SUM(payment_amount) = DECIMAL '3500.00'
            AND MAX(payment_amount) = DECIMAL '1500.00'
            AND MIN(payment_amount) = DECIMAL  '500.00'
           THEN 'PASS' ELSE 'FAIL'
       END                                                  AS result
FROM (
    WITH
    inv_sched AS (
        SELECT supplier_id, invoice_ammount, due_date,
            date_diff('month',
                date_trunc('month', current_date),
                date_trunc('month', due_date)) AS num_payments
        FROM INVOICE
        WHERE supplier_id = 1
    ),
    pay_series AS (
        SELECT
            s.supplier_id, s.invoice_ammount, s.num_payments, k,
            CASE
                WHEN k = s.num_payments
                    THEN s.invoice_ammount
                         - CAST((s.num_payments - 1) AS DECIMAL(10, 4))
                           * ROUND(CAST(s.invoice_ammount AS DECIMAL(10, 4))
                                   / CAST(s.num_payments  AS DECIMAL(10, 4)), 2)
                ELSE ROUND(CAST(s.invoice_ammount AS DECIMAL(10, 4))
                           / CAST(s.num_payments  AS DECIMAL(10, 4)), 2)
            END AS actual_payment,
            date_add('day', -1,
                date_add('month', k,
                    date_trunc('month', current_date))) AS payment_date
        FROM inv_sched s
        CROSS JOIN UNNEST(sequence(1, s.num_payments)) AS t(k)
    )
    SELECT
        CAST(SUM(actual_payment) AS DECIMAL(8, 2)) AS payment_amount
    FROM pay_series
    GROUP BY supplier_id, payment_date
) catering_months;


-- T12: Every supplier's final payment closes their balance to exactly 0.00
--      (5 suppliers should all appear with balance_outstanding = 0.00 on last payment)
SELECT 'T12: All suppliers close balance to 0.00'           AS test_name,
       CASE WHEN COUNT(*) = 5 THEN 'PASS' ELSE 'FAIL' END  AS result
FROM (
    WITH
    inv_sched AS (
        SELECT supplier_id, invoice_ammount, due_date,
            date_diff('month',
                date_trunc('month', current_date),
                date_trunc('month', due_date)) AS num_payments
        FROM INVOICE
    ),
    pay_series AS (
        SELECT
            s.supplier_id, s.invoice_ammount, s.num_payments, k,
            CASE
                WHEN k = s.num_payments
                    THEN s.invoice_ammount
                         - CAST((s.num_payments - 1) AS DECIMAL(10, 4))
                           * ROUND(CAST(s.invoice_ammount AS DECIMAL(10, 4))
                                   / CAST(s.num_payments  AS DECIMAL(10, 4)), 2)
                ELSE ROUND(CAST(s.invoice_ammount AS DECIMAL(10, 4))
                           / CAST(s.num_payments  AS DECIMAL(10, 4)), 2)
            END AS actual_payment,
            date_add('day', -1,
                date_add('month', k,
                    date_trunc('month', current_date))) AS payment_date
        FROM inv_sched s
        CROSS JOIN UNNEST(sequence(1, s.num_payments)) AS t(k)
    ),
    monthly_pay AS (
        SELECT supplier_id, payment_date,
            CAST(SUM(actual_payment) AS DECIMAL(8, 2)) AS payment_amount
        FROM pay_series
        GROUP BY supplier_id, payment_date
    ),
    sup_total AS (
        SELECT supplier_id,
            CAST(SUM(invoice_ammount) AS DECIMAL(8, 2)) AS total_balance
        FROM INVOICE
        GROUP BY supplier_id
    ),
    with_balance AS (
        SELECT
            mp.supplier_id,
            CAST(
                st.total_balance
                - SUM(mp.payment_amount) OVER (
                    PARTITION BY mp.supplier_id
                    ORDER BY     mp.payment_date
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                  )
            AS DECIMAL(8, 2))                                       AS balance_outstanding,
            ROW_NUMBER() OVER (
                PARTITION BY mp.supplier_id
                ORDER BY     mp.payment_date DESC
            )                                                       AS rn
        FROM monthly_pay mp
        JOIN sup_total st ON mp.supplier_id = st.supplier_id
    )
    SELECT supplier_id
    FROM   with_balance
    WHERE  rn = 1
      AND  balance_outstanding = DECIMAL '0.00'
) final_balances;
