USE memory.default;

CREATE TABLE EXPENSE (
    employee_id TINYINT,
    unit_price  DECIMAL(8, 2),
    quantity    TINYINT
);

-- Employee names resolved to IDs from EMPLOYEE table.
-- Source files: finance/receipts_from_last_night/
INSERT INTO EXPENSE (employee_id, unit_price, quantity) VALUES
    -- Alex Jacobson (employee_id = 3)
    (TINYINT '3', DECIMAL  '6.50', TINYINT '14'),  
    (TINYINT '3', DECIMAL '11.00', TINYINT '20'), 
    (TINYINT '3', DECIMAL '22.00', TINYINT '18'),  
    (TINYINT '3', DECIMAL '13.00', TINYINT '75'),   
    -- Andrea Ghibaudi (employee_id = 9)
    (TINYINT '9', DECIMAL '300.00', TINYINT '1'),   
    -- Darren Poynton (employee_id = 4)
    (TINYINT '4', DECIMAL '40.00',  TINYINT '9'),  
    -- Umberto Torrielli (employee_id = 2)
    (TINYINT '2', DECIMAL '17.50',  TINYINT '4');  
