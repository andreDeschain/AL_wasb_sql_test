USE memory.default;

-- Detect employees who are part of a manager approval cycle.
--
-- Algorithm walks the manager chain from each employee.
-- The VISITED array prevents infinite loops when the path enters someone else's cycle)
-- When current_id returns to start_id the cycle is confirmed and the row surfaces in the final SELECT.
--
-- Output: one row per employee in a cycle.
--   employee_id  -- the employee involved in the cycle
--   cycle        -- the full cycle path as a string (e.g. '1 -> 4 -> 2 -> 1')

-- Step 1: materialise the recursive expansion into a temp table to reduce query stages
CREATE TABLE manager_chain_temp AS
WITH RECURSIVE manager_chain(start_id, current_id, path, visited) AS (

    -- Base: step from each employee to their direct manager
    SELECT
        employee_id                                                                   AS start_id,
        manager_id                                                                    AS current_id,
        CAST(employee_id AS VARCHAR) || ' -> ' || CAST(manager_id AS VARCHAR)        AS path,
        ARRAY[employee_id]                                                            AS visited
    FROM EMPLOYEE
    WHERE manager_id IS NOT NULL

    UNION ALL

    -- Recursive: follow the manager chain one step further
    SELECT
        mc.start_id,
        e.manager_id                                                                  AS current_id,
        mc.path || ' -> ' || CAST(e.manager_id AS VARCHAR)                           AS path,
        mc.visited || ARRAY[mc.current_id]                                           AS visited
    FROM manager_chain mc
    JOIN EMPLOYEE e ON mc.current_id = e.employee_id
    WHERE e.manager_id IS NOT NULL
      AND mc.current_id <> mc.start_id            -- stop once the cycle closes
      AND NOT contains(mc.visited, mc.current_id) -- avoid re-traversing visited nodes
)
SELECT * FROM manager_chain;

-- Step 2: surface only the rows where the chain looped back to the starting employee
SELECT
    start_id AS employee_id,
    path     AS cycle
FROM manager_chain_temp
WHERE current_id = start_id
ORDER BY employee_id;

-- Step 3: clean up temp table
DROP TABLE manager_chain_temp;
