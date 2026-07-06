USE memory.default;

-- Report every employee whose total expensed amount exceeds 1000.
-- total_expensed_amount = SUM(unit_price * quantity) across all their EXPENSE rows.
-- Results ordered by total_expensed_amount descending.

SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name                               AS employee_name,
    e.manager_id,
    m.first_name || ' ' || m.last_name                               AS manager_name,
    CAST(SUM(ex.unit_price * ex.quantity) AS DECIMAL(10, 2))         AS total_expensed_amount
FROM       EMPLOYEE  e
JOIN       EXPENSE   ex ON e.employee_id = ex.employee_id
JOIN       EMPLOYEE  m  ON e.manager_id  = m.employee_id
GROUP BY   e.employee_id, e.first_name, e.last_name,
           e.manager_id,  m.first_name, m.last_name
HAVING     SUM(ex.unit_price * ex.quantity) > 1000
ORDER BY   total_expensed_amount DESC;
