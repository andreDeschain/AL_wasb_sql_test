USE memory.default;

CREATE TABLE EMPLOYEE (
    employee_id TINYINT,
    first_name  VARCHAR,
    last_name   VARCHAR,
    job_title   VARCHAR,
    manager_id  TINYINT
);

INSERT INTO EMPLOYEE (employee_id, first_name, last_name, job_title, manager_id) VALUES
    (TINYINT '1', 'Ian',     'James',    'CEO',           TINYINT '4'),
    (TINYINT '2', 'Umberto', 'Torrielli','CSO',           TINYINT '1'),
    (TINYINT '3', 'Alex',    'Jacobson', 'MD EMEA',       TINYINT '2'),
    (TINYINT '4', 'Darren',  'Poynton',  'CFO',           TINYINT '2'),
    (TINYINT '5', 'Tim',     'Beard',    'MD APAC',       TINYINT '2'),
    (TINYINT '6', 'Gemma',   'Dodd',     'COS',           TINYINT '1'),
    (TINYINT '7', 'Lisa',    'Platten',  'CHR',           TINYINT '6'),
    (TINYINT '8', 'Stefano', 'Camisaca', 'GM Activation', TINYINT '2'),
    (TINYINT '9', 'Andrea',  'Ghibaudi', 'MD NAM',        TINYINT '2');
