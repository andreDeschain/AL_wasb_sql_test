USE memory.default;


CREATE TABLE SUPPLIER (
    supplier_id TINYINT,
    name        VARCHAR
);

-- Column name 'invoice_ammount' preserved double 'm' as a typo expecting "production" is the same
CREATE TABLE INVOICE (
    supplier_id     TINYINT,
    invoice_ammount DECIMAL(8, 2),
    due_date        DATE
);

-- supplier_id assigned in strict alphabetical order by company name
INSERT INTO SUPPLIER (supplier_id, name) VALUES
    (TINYINT '1', 'Catering Plus'),
    (TINYINT '2', 'Dave''s Discos'),
    (TINYINT '3', 'Entertainment tonight'),
    (TINYINT '4', 'Ice Ice Baby'),
    (TINYINT '5', 'Party Animals');

-- Due dates are computed dynamically: "N months from now" = last day of month N months ahead.
INSERT INTO INVOICE (supplier_id, invoice_ammount, due_date)
SELECT
    CAST(supplier_id      AS TINYINT),
    CAST(invoice_ammount  AS DECIMAL(8, 2)),
    date_add('day', -1,
        date_add('month', months_from_now + 1,
            date_trunc('month', current_date)
        )
    ) AS due_date
FROM (
    VALUES
        (1, 2000.00, 2),   -- brilliant_bottles.txt:     Catering Plus,          2 months
        (1, 1500.00, 3),   -- crazy_catering.txt:        Catering Plus,          3 months
        (2,  500.00, 1),   -- disco_dj.txt:              Dave's Discos,          1 month
        (3, 6000.00, 3),   -- excellent_entertainment:   Entertainment tonight,  3 months
        (4, 4000.00, 6),   -- fantastic_ice_sculptures:  Ice Ice Baby,           6 months
        (5, 6000.00, 3)    -- awesome_animals.txt:       Party Animals,          3 months
) AS t(supplier_id, invoice_ammount, months_from_now);
