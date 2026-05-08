-- ============================================================
--  UNIFINA GROUP — HR ATTENDANCE MANAGEMENT SYSTEM
--  MySQL Database | Enterprise Financial Services Company
--  Branches: Cairo HQ (Maadi) & New Cairo Branch
--  Business Lines: Investment Management | Home Financing | Equipment Leasing | Insurance
-- ============================================================

CREATE DATABASE IF NOT EXISTS unifina_group;
USE unifina_group;

-- ============================================================
-- TABLE: branches
-- ============================================================
CREATE TABLE branches (
    branch_id       INT AUTO_INCREMENT PRIMARY KEY,
    branch_name     VARCHAR(100) NOT NULL,
    branch_code     VARCHAR(10) UNIQUE NOT NULL,
    city            VARCHAR(50) NOT NULL,
    address         VARCHAR(255),
    phone           VARCHAR(20),
    email           VARCHAR(100),
    floors          TINYINT DEFAULT 5,
    capacity        INT COMMENT 'Max headcount',
    established     DATE,
    is_hq           BOOLEAN DEFAULT FALSE
);

INSERT INTO branches (branch_name, branch_code, city, address, phone, email, floors, capacity, established, is_hq) VALUES
('UNIFINA Group — Cairo HQ',        'CAI-HQ',  'Cairo',     '15 El-Lasilky St, Maadi, Cairo',              '0225209000', 'hq@unifina.com.eg',       6, 220, '2012-01-15', TRUE),
('UNIFINA Group — New Cairo Branch','NCA-BR',  'New Cairo', 'Building 7, Southern 90th St, New Cairo',     '0225509100', 'newcairo@unifina.com.eg', 5, 180, '2016-06-01', FALSE);


-- ============================================================
-- TABLE: departments
-- ============================================================
CREATE TABLE departments (
    department_id   INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    division        ENUM('Investment Management','Home Financing','Equipment Leasing','Insurance','Corporate') NOT NULL,
    branch_id       INT NOT NULL,
    floor_number    TINYINT,
    wing            VARCHAR(10),
    manager_id      INT NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);


-- ============================================================
-- TABLE: employees
-- ============================================================
CREATE TABLE employees (
    employee_id         INT AUTO_INCREMENT PRIMARY KEY,
    first_name          VARCHAR(50) NOT NULL,
    last_name           VARCHAR(50) NOT NULL,
    email               VARCHAR(100) UNIQUE NOT NULL,
    phone               VARCHAR(20),
    department_id       INT,
    branch_id           INT NOT NULL,
    job_title           VARCHAR(100),
    employment_type     ENUM('Full-Time','Part-Time','Contractor') DEFAULT 'Full-Time',
    salary              DECIMAL(10,2),
    hire_date           DATE,
    birth_date          DATE,
    gender              ENUM('Male','Female') NOT NULL,
    national_id         VARCHAR(20) UNIQUE,
    address             VARCHAR(255),
    status              ENUM('Active','Inactive','On Leave') DEFAULT 'Active',
    work_arrangement    ENUM('On-Site','Remote','Hybrid') DEFAULT 'On-Site',
    remote_days_per_week TINYINT DEFAULT 0 COMMENT '0 = fully on-site, 5 = fully remote',
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);


-- ============================================================
-- TABLE: rfid_cards
-- ============================================================
CREATE TABLE rfid_cards (
    card_id         INT AUTO_INCREMENT PRIMARY KEY,
    card_uid        VARCHAR(50) UNIQUE NOT NULL,
    employee_id     INT UNIQUE,
    issued_date     DATE NOT NULL,
    expiry_date     DATE GENERATED ALWAYS AS (DATE_ADD(issued_date, INTERVAL 3 YEAR)) STORED,
    is_active       BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);


-- ============================================================
-- TABLE: shifts
-- ============================================================
CREATE TABLE shifts (
    shift_id        INT AUTO_INCREMENT PRIMARY KEY,
    shift_name      VARCHAR(50) NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    break_minutes   INT DEFAULT 60,
    applicable_to   ENUM('On-Site','Remote','All') DEFAULT 'All'
);


-- ============================================================
-- TABLE: employee_shifts
-- ============================================================
CREATE TABLE employee_shifts (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    employee_id     INT,
    shift_id        INT,
    effective_from  DATE NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (shift_id) REFERENCES shifts(shift_id)
);


-- ============================================================
-- TABLE: attendance
--   Tracks both physical RFID scans and remote work log-ins
--   scan_source: 'RFID' = physical card, 'System' = remote login
-- ============================================================
CREATE TABLE attendance (
    attendance_id       INT AUTO_INCREMENT PRIMARY KEY,
    employee_id         INT NOT NULL,
    card_uid            VARCHAR(50),
    scan_time           DATETIME NOT NULL,
    scan_type           ENUM('Check-In','Check-Out') NOT NULL,
    reader_location     VARCHAR(100) DEFAULT 'Main Entrance',
    scan_source         ENUM('RFID','System','Manual') DEFAULT 'RFID'
                            COMMENT 'RFID=physical scan, System=remote login, Manual=HR override',
    attendance_type     ENUM('On-Site','Work-From-Home') DEFAULT 'On-Site',
    status              ENUM('On Time','Late','Early Leave','Absent') DEFAULT 'On Time',
    notes               VARCHAR(255),
    branch_id           INT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);


-- ============================================================
-- TABLE: work_from_home_requests
-- ============================================================
CREATE TABLE work_from_home_requests (
    wfh_id          INT AUTO_INCREMENT PRIMARY KEY,
    employee_id     INT NOT NULL,
    request_date    DATE NOT NULL,
    reason          TEXT,
    status          ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    reviewed_by     INT NULL,
    requested_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (reviewed_by) REFERENCES employees(employee_id)
);


-- ============================================================
-- TABLE: leave_types
-- ============================================================
CREATE TABLE leave_types (
    leave_type_id   INT AUTO_INCREMENT PRIMARY KEY,
    type_name       VARCHAR(50) NOT NULL,
    max_days_per_year INT DEFAULT 14,
    is_paid         BOOLEAN DEFAULT TRUE
);


-- ============================================================
-- TABLE: leave_requests
-- ============================================================
CREATE TABLE leave_requests (
    leave_id        INT AUTO_INCREMENT PRIMARY KEY,
    employee_id     INT NOT NULL,
    leave_type_id   INT NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    total_days      INT,
    reason          TEXT,
    status          ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    reviewed_by     INT NULL,
    requested_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (leave_type_id) REFERENCES leave_types(leave_type_id),
    FOREIGN KEY (reviewed_by) REFERENCES employees(employee_id)
);


-- ============================================================
-- TABLE: payroll
-- ============================================================
CREATE TABLE payroll (
    payroll_id      INT AUTO_INCREMENT PRIMARY KEY,
    employee_id     INT NOT NULL,
    month           TINYINT NOT NULL,
    year            YEAR NOT NULL,
    base_salary     DECIMAL(10,2),
    overtime_hours  DECIMAL(5,2) DEFAULT 0,
    overtime_pay    DECIMAL(10,2) DEFAULT 0,
    deductions      DECIMAL(10,2) DEFAULT 0,
    net_salary      DECIMAL(10,2),
    paid_on         DATE,
    status          ENUM('Pending','Paid') DEFAULT 'Pending',
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);


-- ============================================================
-- TABLE: rfid_unknown_scans  (security events)
-- ============================================================
CREATE TABLE rfid_unknown_scans (
    scan_id         INT AUTO_INCREMENT PRIMARY KEY,
    card_uid        VARCHAR(50) NOT NULL,
    scan_time       DATETIME NOT NULL,
    reader_location VARCHAR(100),
    branch_id       INT,
    flagged         BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);


-- ============================================================
-- TABLE: rfid_scan_log
--   Raw log of EVERY scan event — both recognized and unknown
--   This is the primary table updated by the RFID scanner function
-- ============================================================
CREATE TABLE rfid_scan_log (
    log_id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    card_uid        VARCHAR(50) NOT NULL,
    scan_time       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reader_location VARCHAR(100),
    branch_id       INT,
    resolved        BOOLEAN DEFAULT FALSE
                        COMMENT 'TRUE after processed into attendance or unknown_scans',
    INDEX idx_card_uid (card_uid),
    INDEX idx_scan_time (scan_time)
);


-- ============================================================
-- STORED PROCEDURE: sp_process_rfid_scan
--   Call this whenever an RFID card is scanned at a reader.
--   Automatically determines Check-In vs Check-Out,
--   resolves employee, updates attendance, and flags unknowns.
-- 
--   Usage:
--     CALL sp_process_rfid_scan('A1B2C3D4', 'Main Entrance', 1);
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_process_rfid_scan(
    IN  p_card_uid      VARCHAR(50),
    IN  p_location      VARCHAR(100),
    IN  p_branch_id     INT
)
BEGIN
    DECLARE v_employee_id   INT DEFAULT NULL;
    DECLARE v_card_active   BOOLEAN DEFAULT FALSE;
    DECLARE v_last_type     VARCHAR(20) DEFAULT NULL;
    DECLARE v_new_type      VARCHAR(20);
    DECLARE v_shift_start   TIME;
    DECLARE v_late_cutoff   TIME;
    DECLARE v_att_status    VARCHAR(20) DEFAULT 'On Time';
    DECLARE v_now           DATETIME DEFAULT NOW();

    -- 1. Log the raw scan regardless of outcome
    INSERT INTO rfid_scan_log (card_uid, scan_time, reader_location, branch_id)
    VALUES (p_card_uid, v_now, p_location, p_branch_id);

    -- 2. Look up employee & card status
    SELECT rc.employee_id, rc.is_active
    INTO   v_employee_id, v_card_active
    FROM   rfid_cards rc
    WHERE  rc.card_uid = p_card_uid
    LIMIT  1;

    -- 3a. Unknown or inactive card → flag it
    IF v_employee_id IS NULL OR v_card_active = FALSE THEN
        INSERT INTO rfid_unknown_scans (card_uid, scan_time, reader_location, branch_id, flagged)
        VALUES (p_card_uid, v_now, p_location, p_branch_id, TRUE);

        UPDATE rfid_scan_log SET resolved = TRUE
        WHERE  card_uid = p_card_uid AND scan_time = v_now;

        SELECT 'UNKNOWN_OR_INACTIVE' AS result,
               p_card_uid            AS card_uid,
               NULL                  AS employee_id,
               v_now                 AS scan_time;
    ELSE
        -- 3b. Determine Check-In vs Check-Out
        --     Rule: last scan today for this employee determines toggle
        SELECT a.scan_type
        INTO   v_last_type
        FROM   attendance a
        WHERE  a.employee_id = v_employee_id
          AND  DATE(a.scan_time) = DATE(v_now)
        ORDER BY a.scan_time DESC
        LIMIT 1;

        IF v_last_type IS NULL OR v_last_type = 'Check-Out' THEN
            SET v_new_type = 'Check-In';
        ELSE
            SET v_new_type = 'Check-Out';
        END IF;

        -- 3c. Determine attendance status for Check-In
        IF v_new_type = 'Check-In' THEN
            -- Get employee's shift start time
            SELECT s.start_time
            INTO   v_shift_start
            FROM   employee_shifts es
            JOIN   shifts s ON es.shift_id = s.shift_id
            WHERE  es.employee_id = v_employee_id
            ORDER BY es.effective_from DESC
            LIMIT  1;

            IF v_shift_start IS NOT NULL THEN
                SET v_late_cutoff = ADDTIME(v_shift_start, '00:15:00');
                IF TIME(v_now) > v_late_cutoff THEN
                    SET v_att_status = 'Late';
                END IF;
            END IF;
        ELSE
            -- Check-Out: check for early leave
            SELECT s.end_time
            INTO   v_shift_start
            FROM   employee_shifts es
            JOIN   shifts s ON es.shift_id = s.shift_id
            WHERE  es.employee_id = v_employee_id
            ORDER BY es.effective_from DESC
            LIMIT  1;

            IF v_shift_start IS NOT NULL THEN
                SET v_late_cutoff = SUBTIME(v_shift_start, '00:30:00');
                IF TIME(v_now) < v_late_cutoff THEN
                    SET v_att_status = 'Early Leave';
                END IF;
            END IF;
        END IF;

        -- 3d. Insert attendance record
        INSERT INTO attendance
            (employee_id, card_uid, scan_time, scan_type, reader_location, scan_source, attendance_type, status, branch_id)
        VALUES
            (v_employee_id, p_card_uid, v_now, v_new_type, p_location, 'RFID', 'On-Site', v_att_status, p_branch_id);

        -- 3e. Mark raw log as resolved
        UPDATE rfid_scan_log SET resolved = TRUE
        WHERE  card_uid = p_card_uid AND scan_time = v_now;

        -- 3f. Return result to caller
        SELECT 'OK'                AS result,
               p_card_uid         AS card_uid,
               v_employee_id      AS employee_id,
               v_new_type         AS scan_type,
               v_att_status       AS status,
               v_now              AS scan_time,
               p_location         AS location;
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- DATA: departments — dual branch, 4 business lines + Corporate
-- ============================================================

-- ── CAIRO HQ (branch_id = 1) ────────────────────────────────
INSERT INTO departments (name, division, branch_id, floor_number, wing, manager_id) VALUES
-- Corporate
('Executive & Strategy',        'Corporate',            1, 6,    'A',  NULL),
('Human Resources',             'Corporate',            1, 1,    'A',  NULL),
('Finance & Accounting',        'Corporate',            1, 1,    'B',  NULL),
('IT & Infrastructure',         'Corporate',            1, 2,    'C',  NULL),
('Legal & Compliance',          'Corporate',            1, 2,    'A',  NULL),
-- Investment Management
('Portfolio Management',        'Investment Management',1, 3,    'A',  NULL),
('Research & Analysis',         'Investment Management',1, 3,    'B',  NULL),
('Client Relations — Invest',   'Investment Management',1, 4,    'A',  NULL),
-- Home Financing
('Mortgage Origination',        'Home Financing',       1, 4,    'B',  NULL),
('Mortgage Underwriting',       'Home Financing',       1, 5,    'A',  NULL),
('Loan Servicing',              'Home Financing',       1, 5,    'B',  NULL),
-- Equipment Leasing
('Leasing Sales',               'Equipment Leasing',    1, 5,    'C',  NULL),
('Asset Management',            'Equipment Leasing',    1, 6,    'B',  NULL),
-- Insurance
('Insurance Products',          'Insurance',            1, 6,    'C',  NULL),
('Claims & Risk',               'Insurance',            1, 6,    'D',  NULL);

-- ── NEW CAIRO BRANCH (branch_id = 2) ────────────────────────
INSERT INTO departments (name, division, branch_id, floor_number, wing, manager_id) VALUES
-- Corporate support
('Branch Operations',           'Corporate',            2, 1,    'A',  NULL),
('Branch HR & Admin',           'Corporate',            2, 1,    'B',  NULL),
('Branch IT Support',           'Corporate',            2, 2,    'A',  NULL),
-- Investment
('Investment Advisory',         'Investment Management',2, 2,    'B',  NULL),
('Retail Investments',          'Investment Management',2, 3,    'A',  NULL),
-- Home Financing
('Mortgage Sales — NC',         'Home Financing',       2, 3,    'B',  NULL),
('Property Valuation',          'Home Financing',       2, 4,    'A',  NULL),
-- Equipment Leasing
('Leasing Advisory — NC',       'Equipment Leasing',    2, 4,    'B',  NULL),
-- Insurance
('Insurance Sales — NC',        'Insurance',            2, 5,    'A',  NULL),
('Auto & Home Insurance',       'Insurance',            2, 5,    'B',  NULL);


-- ============================================================
-- DATA: shifts
-- ============================================================
INSERT INTO shifts (shift_name, start_time, end_time, break_minutes, applicable_to) VALUES
('Standard Office',     '09:00:00', '17:00:00', 60,  'On-Site'),
('Early Shift',         '07:30:00', '15:30:00', 60,  'On-Site'),
('Evening Shift',       '13:00:00', '21:00:00', 60,  'On-Site'),
('Flexible Office',     '08:00:00', '18:00:00', 60,  'On-Site'),
('Remote Standard',     '09:00:00', '17:00:00', 60,  'Remote'),
('Remote Flexible',     '08:00:00', '18:00:00', 60,  'Remote');


-- ============================================================
-- DATA: employees (50 employees across both branches)
-- ============================================================
INSERT INTO employees (first_name, last_name, email, phone, department_id, branch_id, job_title, salary, hire_date, birth_date, gender, national_id, address, status, work_arrangement, remote_days_per_week) VALUES

-- ── CAIRO HQ ──────────────────────────────────────────────────────────────────
-- dept 1: Executive & Strategy
('Tarek',     'Mansour',    'tarek.mansour@unifina.com.eg',     '01001000001', 1,  1, 'CEO',                          85000.00, '2012-01-15', '1972-03-10', 'Male',   '27203101234501', 'Cairo, Zamalek',          'Active',    'On-Site', 0),
('Sherine',   'El-Masry',   'sherine.elmasry@unifina.com.eg',   '01001000002', 1,  1, 'COO',                          72000.00, '2013-05-01', '1975-08-22', 'Female', '27508221234502', 'Cairo, Maadi',            'Active',    'On-Site', 0),
('Hossam',    'Badawi',     'hossam.badawi@unifina.com.eg',     '01001000003', 1,  1, 'Chief Strategy Officer',       65000.00, '2014-02-20', '1978-11-05', 'Male',   '27811051234503', 'Cairo, New Cairo',        'Active',    'Hybrid',  1),

-- dept 2: Human Resources
('Dina',      'Kamel',      'dina.kamel@unifina.com.eg',        '01001000004', 2,  1, 'HR Director',                  35000.00, '2014-07-10', '1980-04-17', 'Female', '28004171234504', 'Cairo, Heliopolis',       'Active',    'On-Site', 0),
('Omar',      'Farag',      'omar.farag@unifina.com.eg',        '01001000005', 2,  1, 'HR Manager',                   22000.00, '2017-03-01', '1985-09-30', 'Male',   '28509301234505', 'Cairo, Nasr City',        'Active',    'Hybrid',  2),
('Amira',     'Soliman',    'amira.soliman@unifina.com.eg',     '01001000006', 2,  1, 'Recruitment Specialist',       13500.00, '2020-06-15', '1994-02-12', 'Female', '29402121234506', 'Giza, Dokki',             'Active',    'Hybrid',  2),
('Kareem',    'Abdalla',    'kareem.abdalla@unifina.com.eg',    '01001000007', 2,  1, 'HR Officer',                   11000.00, '2022-01-10', '1998-07-01', 'Male',   '29807011234507', 'Cairo, Shubra',           'Active',    'On-Site', 0),

-- dept 3: Finance & Accounting
('Walid',     'Fouad',      'walid.fouad@unifina.com.eg',       '01001000008', 3,  1, 'CFO',                          68000.00, '2012-01-15', '1973-06-28', 'Male',   '27306281234508', 'Cairo, Garden City',      'Active',    'On-Site', 0),
('Rania',     'El-Sayed',   'rania.elsayed@unifina.com.eg',     '01001000009', 3,  1, 'Finance Manager',              30000.00, '2015-09-01', '1982-12-14', 'Female', '28212141234509', 'Cairo, Heliopolis',       'Active',    'On-Site', 0),
('Hassan',    'Gomaa',      'hassan.gomaa@unifina.com.eg',      '01001000010', 3,  1, 'Senior Accountant',            18500.00, '2018-04-15', '1989-03-22', 'Male',   '28903221234510', 'Cairo, Nasr City',        'Active',    'Hybrid',  1),

-- dept 4: IT & Infrastructure
('Mahmoud',   'Zahran',     'mahmoud.zahran@unifina.com.eg',    '01001000011', 4,  1, 'IT Director',                  40000.00, '2014-11-01', '1979-07-09', 'Male',   '27907091234511', 'Cairo, Maadi',            'Active',    'On-Site', 0),
('Layla',     'Nour',       'layla.nour@unifina.com.eg',        '01001000012', 4,  1, 'Senior DevOps Engineer',       25000.00, '2019-02-18', '1991-05-15', 'Female', '29105151234512', 'Cairo, New Cairo',        'Active',    'Remote',  5),
('Bilal',     'Khamis',     'bilal.khamis@unifina.com.eg',      '01001000013', 4,  1, 'Network Engineer',             18000.00, '2020-08-01', '1993-10-03', 'Male',   '29310031234513', 'Giza, 6th October',       'Active',    'Hybrid',  3),

-- dept 5: Legal & Compliance
('Sara',      'Hafez',      'sara.hafez@unifina.com.eg',        '01001000014', 5,  1, 'Chief Legal Officer',          58000.00, '2013-03-10', '1977-01-25', 'Female', '27701251234514', 'Cairo, Zamalek',          'Active',    'On-Site', 0),
('Ahmed',     'El-Rashidy', 'ahmed.elrashidy@unifina.com.eg',   '01001000015', 5,  1, 'Compliance Manager',           32000.00, '2016-07-20', '1983-04-11', 'Male',   '28304111234515', 'Cairo, Maadi',            'Active',    'On-Site', 0),

-- dept 6: Portfolio Management
('Yasmin',    'Sherif',     'yasmin.sherif@unifina.com.eg',     '01001000016', 6,  1, 'Head of Portfolio Management', 52000.00, '2015-02-01', '1980-09-07', 'Female', '28009071234516', 'Cairo, Zamalek',          'Active',    'Hybrid',  1),
('Youssef',   'Tawfik',     'youssef.tawfik@unifina.com.eg',   '01001000017', 6,  1, 'Senior Portfolio Manager',     38000.00, '2017-06-12', '1986-02-18', 'Male',   '28602181234517', 'Cairo, New Cairo',        'Active',    'Hybrid',  2),
('Nour',      'Ibrahim',    'nour.ibrahim@unifina.com.eg',      '01001000018', 6,  1, 'Portfolio Analyst',            22000.00, '2021-03-01', '1995-11-30', 'Female', '29511301234518', 'Cairo, Heliopolis',       'Active',    'Hybrid',  2),

-- dept 7: Research & Analysis
('Mohamed',   'Shalaby',    'mohamed.shalaby@unifina.com.eg',   '01001000019', 7,  1, 'Head of Research',             45000.00, '2016-09-01', '1981-07-14', 'Male',   '28107141234519', 'Cairo, Maadi',            'Active',    'Hybrid',  2),
('Hana',      'Samir',      'hana.samir@unifina.com.eg',        '01001000020', 7,  1, 'Senior Research Analyst',      28000.00, '2019-11-01', '1990-03-25', 'Female', '29003251234520', 'Giza, Mohandessin',       'Active',    'Remote',  5),

-- dept 8: Client Relations — Investment
('Ashraf',    'Lotfy',      'ashraf.lotfy@unifina.com.eg',      '01001000021', 8,  1, 'Senior Client Advisor',        30000.00, '2018-01-15', '1984-06-08', 'Male',   '28406081234521', 'Cairo, New Cairo',        'Active',    'On-Site', 0),
('Mona',      'Adel',       'mona.adel@unifina.com.eg',         '01001000022', 8,  1, 'Client Relations Officer',     18000.00, '2020-05-10', '1993-09-16', 'Female', '29309161234522', 'Cairo, Heliopolis',       'Active',    'Hybrid',  1),

-- dept 9: Mortgage Origination
('Karim',     'Nasser',     'karim.nasser@unifina.com.eg',      '01001000023', 9,  1, 'Head of Mortgage Origination', 42000.00, '2015-08-01', '1980-12-20', 'Male',   '28012201234523', 'Cairo, Zamalek',          'Active',    'On-Site', 0),
('Rana',      'Magdy',      'rana.magdy@unifina.com.eg',        '01001000024', 9,  1, 'Mortgage Loan Officer',        20000.00, '2019-04-01', '1992-05-07', 'Female', '29205071234524', 'Giza, Dokki',             'Active',    'On-Site', 0),

-- dept 10: Mortgage Underwriting
('Tarek',     'Salah',      'tarek.salah@unifina.com.eg',       '01001000025', 10, 1, 'Senior Underwriter',           32000.00, '2017-11-15', '1985-08-30', 'Male',   '28508301234525', 'Cairo, Nasr City',        'Active',    'Hybrid',  1),

-- dept 11: Loan Servicing
('Nadia',     'Kamal',      'nadia.kamal@unifina.com.eg',       '01001000026', 11, 1, 'Loan Servicing Manager',       28000.00, '2018-06-01', '1987-02-14', 'Female', '28702141234526', 'Cairo, Heliopolis',       'Active',    'On-Site', 0),
('Islam',     'Fouad',      'islam.fouad@unifina.com.eg',       '01001000027', 11, 1, 'Loan Officer',                 17000.00, '2021-09-01', '1995-07-22', 'Male',   '29507221234527', 'Giza, 6th October',       'Active',    'On-Site', 0),

-- dept 12: Leasing Sales
('Sameh',     'Osman',      'sameh.osman@unifina.com.eg',       '01001000028', 12, 1, 'Head of Leasing Sales',        38000.00, '2016-03-01', '1982-10-04', 'Male',   '28210041234528', 'Cairo, Maadi',            'Active',    'On-Site', 0),
('Farah',     'Nabil',      'farah.nabil@unifina.com.eg',       '01001000029', 12, 1, 'Leasing Sales Executive',      19000.00, '2020-07-01', '1996-04-19', 'Female', '29604191234529', 'Cairo, New Cairo',        'Active',    'Hybrid',  2),

-- dept 13: Asset Management
('Ziad',      'Aziz',       'ziad.aziz@unifina.com.eg',         '01001000030', 13, 1, 'Asset Manager',                33000.00, '2017-05-10', '1984-01-11', 'Male',   '28401111234530', 'Cairo, Garden City',      'Active',    'On-Site', 0),

-- dept 14: Insurance Products
('Amr',       'Sayed',      'amr.sayed@unifina.com.eg',         '01001000031', 14, 1, 'Head of Insurance Products',   40000.00, '2015-10-01', '1978-06-17', 'Male',   '27806171234531', 'Cairo, Zamalek',          'Active',    'On-Site', 0),
('Heba',      'Morsi',      'heba.morsi@unifina.com.eg',        '01001000032', 14, 1, 'Insurance Product Specialist', 22000.00, '2019-08-12', '1991-11-25', 'Female', '29111251234532', 'Cairo, Shubra',           'Active',    'Hybrid',  2),

-- dept 15: Claims & Risk
('Noha',      'Selim',      'noha.selim@unifina.com.eg',        '01001000033', 15, 1, 'Claims Manager',               30000.00, '2017-02-01', '1983-08-09', 'Female', '28308091234533', 'Cairo, Maadi',            'Active',    'On-Site', 0),
('Khaled',    'El-Shafei',  'khaled.elshafei@unifina.com.eg',   '01001000034', 15, 1, 'Risk Analyst',                 20000.00, '2020-11-01', '1992-03-31', 'Male',   '29203311234534', 'Cairo, Heliopolis',       'Active',    'Hybrid',  1),

-- ── NEW CAIRO BRANCH ───────────────────────────────────────────────────────────
-- dept 16: Branch Operations
('Reem',      'Abdel-Hamid','reem.abdelhamid@unifina.com.eg',   '01001000035', 16, 2, 'Branch Manager',               48000.00, '2016-06-01', '1978-05-20', 'Female', '27805201234535', 'Cairo, New Cairo',        'Active',    'On-Site', 0),
('Samir',     'Ragab',      'samir.ragab@unifina.com.eg',       '01001000036', 16, 2, 'Operations Supervisor',        24000.00, '2018-09-15', '1984-12-05', 'Male',   '28412051234536', 'Cairo, New Cairo',        'Active',    'On-Site', 0),

-- dept 17: Branch HR & Admin
('Mariam',    'Fahmy',      'mariam.fahmy@unifina.com.eg',      '01001000037', 17, 2, 'Branch HR Manager',            25000.00, '2017-01-20', '1986-03-14', 'Female', '28603141234537', 'Cairo, New Cairo',        'Active',    'Hybrid',  2),
('Mostafa',   'Amin',       'mostafa.amin@unifina.com.eg',      '01001000038', 17, 2, 'HR & Admin Officer',           13000.00, '2021-04-01', '1997-06-28', 'Male',   '29706281234538', 'Cairo, New Cairo',        'Active',    'On-Site', 0),

-- dept 18: Branch IT Support
('Salma',     'Gamal',      'salma.gamal@unifina.com.eg',       '01001000039', 18, 2, 'IT Support Lead',              20000.00, '2019-07-10', '1992-09-11', 'Female', '29209111234539', 'Cairo, New Cairo',        'Active',    'On-Site', 0),

-- dept 19: Investment Advisory
('Ahmed',     'Mostafa',    'ahmed.mostafa@unifina.com.eg',     '01001000040', 19, 2, 'Investment Advisory Manager',  44000.00, '2016-06-01', '1979-11-02', 'Male',   '27911021234540', 'Cairo, New Cairo',        'Active',    'Hybrid',  1),
('Sara',      'Khalil',     'sara.khalil@unifina.com.eg',       '01001000041', 19, 2, 'Investment Advisor',           26000.00, '2019-10-01', '1991-07-18', 'Female', '29107181234541', 'Cairo, New Cairo',        'Active',    'Hybrid',  2),

-- dept 20: Retail Investments
('Mahmoud',   'Hassan',     'mahmoud.hassan@unifina.com.eg',    '01001000042', 20, 2, 'Retail Investment Specialist', 22000.00, '2021-02-01', '1994-04-05', 'Male',   '29404051234542', 'Cairo, New Cairo',        'Active',    'On-Site', 0),

-- dept 21: Mortgage Sales — NC
('Yasmine',   'Abdel-Aziz', 'yasmine.abdelaziz@unifina.com.eg', '01001000043', 21, 2, 'Mortgage Sales Manager',       35000.00, '2017-06-01', '1982-01-29', 'Female', '28201291234543', 'Cairo, New Cairo',        'Active',    'On-Site', 0),
('Wael',      'Ibrahim',    'wael.ibrahim@unifina.com.eg',      '01001000044', 21, 2, 'Mortgage Sales Executive',     19000.00, '2020-09-01', '1993-08-14', 'Male',   '29308141234544', 'Cairo, New Cairo',        'Active',    'On-Site', 0),

-- dept 22: Property Valuation
('Dalia',     'Mansour',    'dalia.mansour@unifina.com.eg',     '01001000045', 22, 2, 'Property Valuation Specialist',24000.00, '2018-11-01', '1988-10-20', 'Female', '28810201234545', 'Cairo, New Cairo',        'Active',    'Hybrid',  2),

-- dept 23: Leasing Advisory — NC
('Hesham',    'El-Gammal',  'hesham.elgammal@unifina.com.eg',   '01001000046', 23, 2, 'Leasing Advisory Manager',    36000.00, '2016-06-01', '1980-07-03', 'Male',   '28007031234546', 'Cairo, New Cairo',        'Active',    'On-Site', 0),

-- dept 24: Insurance Sales — NC
('Nada',      'Hamdi',      'nada.hamdi@unifina.com.eg',        '01001000047', 24, 2, 'Insurance Sales Manager',     32000.00, '2017-03-01', '1983-05-16', 'Female', '28305161234547', 'Cairo, New Cairo',        'Active',    'On-Site', 0),
('Yasser',    'Khalaf',     'yasser.khalaf@unifina.com.eg',     '01001000048', 24, 2, 'Insurance Sales Executive',   18000.00, '2021-06-01', '1996-12-10', 'Male',   '29612101234548', 'Cairo, New Cairo',        'Active',    'On-Site', 0),

-- dept 25: Auto & Home Insurance — NC
('Doaa',      'El-Naggar',  'doaa.elnaggar@unifina.com.eg',     '01001000049', 25, 2, 'Auto Insurance Specialist',   20000.00, '2019-09-01', '1990-02-28', 'Female', '29002281234549', 'Cairo, New Cairo',        'Active',    'Hybrid',  2),
('Ali',       'Taha',       'ali.taha@unifina.com.eg',          '01001000050', 25, 2, 'Home Insurance Specialist',   20000.00, '2020-01-15', '1991-06-07', 'Male',   '29106071234550', 'Cairo, New Cairo',        'Active',    'Hybrid',  2);


-- ============================================================
-- Set department managers
-- ============================================================
UPDATE departments SET manager_id = 1  WHERE department_id = 1;
UPDATE departments SET manager_id = 4  WHERE department_id = 2;
UPDATE departments SET manager_id = 8  WHERE department_id = 3;
UPDATE departments SET manager_id = 11 WHERE department_id = 4;
UPDATE departments SET manager_id = 14 WHERE department_id = 5;
UPDATE departments SET manager_id = 16 WHERE department_id = 6;
UPDATE departments SET manager_id = 19 WHERE department_id = 7;
UPDATE departments SET manager_id = 21 WHERE department_id = 8;
UPDATE departments SET manager_id = 23 WHERE department_id = 9;
UPDATE departments SET manager_id = 25 WHERE department_id = 10;
UPDATE departments SET manager_id = 26 WHERE department_id = 11;
UPDATE departments SET manager_id = 28 WHERE department_id = 12;
UPDATE departments SET manager_id = 30 WHERE department_id = 13;
UPDATE departments SET manager_id = 31 WHERE department_id = 14;
UPDATE departments SET manager_id = 33 WHERE department_id = 15;
UPDATE departments SET manager_id = 35 WHERE department_id = 16;
UPDATE departments SET manager_id = 37 WHERE department_id = 17;
UPDATE departments SET manager_id = 39 WHERE department_id = 18;
UPDATE departments SET manager_id = 40 WHERE department_id = 19;
UPDATE departments SET manager_id = 42 WHERE department_id = 20;
UPDATE departments SET manager_id = 43 WHERE department_id = 21;
UPDATE departments SET manager_id = 45 WHERE department_id = 22;
UPDATE departments SET manager_id = 46 WHERE department_id = 23;
UPDATE departments SET manager_id = 47 WHERE department_id = 24;
UPDATE departments SET manager_id = 49 WHERE department_id = 25;


-- ============================================================
-- DATA: rfid_cards
-- ============================================================
INSERT INTO rfid_cards (card_uid, employee_id, issued_date, is_active) VALUES
('UNF-HQ-001', 1,  '2012-01-15', TRUE),
('UNF-HQ-002', 2,  '2013-05-01', TRUE),
('UNF-HQ-003', 3,  '2014-02-20', TRUE),
('UNF-HQ-004', 4,  '2014-07-10', TRUE),
('UNF-HQ-005', 5,  '2017-03-01', TRUE),
('UNF-HQ-006', 6,  '2020-06-15', TRUE),
('UNF-HQ-007', 7,  '2022-01-10', TRUE),
('UNF-HQ-008', 8,  '2012-01-15', TRUE),
('UNF-HQ-009', 9,  '2015-09-01', TRUE),
('UNF-HQ-010', 10, '2018-04-15', TRUE),
('UNF-HQ-011', 11, '2014-11-01', TRUE),
('UNF-HQ-012', 12, '2019-02-18', FALSE),  -- Remote-only, no physical card needed (inactive)
('UNF-HQ-013', 13, '2020-08-01', TRUE),
('UNF-HQ-014', 14, '2013-03-10', TRUE),
('UNF-HQ-015', 15, '2016-07-20', TRUE),
('UNF-HQ-016', 16, '2015-02-01', TRUE),
('UNF-HQ-017', 17, '2017-06-12', TRUE),
('UNF-HQ-018', 18, '2021-03-01', TRUE),
('UNF-HQ-019', 19, '2016-09-01', TRUE),
('UNF-HQ-020', 20, '2019-11-01', FALSE),  -- Fully remote
('UNF-HQ-021', 21, '2018-01-15', TRUE),
('UNF-HQ-022', 22, '2020-05-10', TRUE),
('UNF-HQ-023', 23, '2015-08-01', TRUE),
('UNF-HQ-024', 24, '2019-04-01', TRUE),
('UNF-HQ-025', 25, '2017-11-15', TRUE),
('UNF-HQ-026', 26, '2018-06-01', TRUE),
('UNF-HQ-027', 27, '2021-09-01', TRUE),
('UNF-HQ-028', 28, '2016-03-01', TRUE),
('UNF-HQ-029', 29, '2020-07-01', TRUE),
('UNF-HQ-030', 30, '2017-05-10', TRUE),
('UNF-HQ-031', 31, '2015-10-01', TRUE),
('UNF-HQ-032', 32, '2019-08-12', TRUE),
('UNF-HQ-033', 33, '2017-02-01', TRUE),
('UNF-HQ-034', 34, '2020-11-01', TRUE),
('UNF-NC-001', 35, '2016-06-01', TRUE),
('UNF-NC-002', 36, '2018-09-15', TRUE),
('UNF-NC-003', 37, '2017-01-20', TRUE),
('UNF-NC-004', 38, '2021-04-01', TRUE),
('UNF-NC-005', 39, '2019-07-10', TRUE),
('UNF-NC-006', 40, '2016-06-01', TRUE),
('UNF-NC-007', 41, '2019-10-01', TRUE),
('UNF-NC-008', 42, '2021-02-01', TRUE),
('UNF-NC-009', 43, '2017-06-01', TRUE),
('UNF-NC-010', 44, '2020-09-01', TRUE),
('UNF-NC-011', 45, '2018-11-01', TRUE),
('UNF-NC-012', 46, '2016-06-01', TRUE),
('UNF-NC-013', 47, '2017-03-01', TRUE),
('UNF-NC-014', 48, '2021-06-01', TRUE),
('UNF-NC-015', 49, '2019-09-01', TRUE),
('UNF-NC-016', 50, '2020-01-15', TRUE);


-- ============================================================
-- DATA: employee_shifts
-- ============================================================
INSERT INTO employee_shifts (employee_id, shift_id, effective_from) VALUES
-- On-Site employees → shift 1 (Standard Office) unless specified
(1,1,'2012-01-15'),(2,1,'2013-05-01'),(3,4,'2014-02-20'),
(4,1,'2014-07-10'),(5,4,'2017-03-01'),(6,4,'2020-06-15'),
(7,1,'2022-01-10'),(8,1,'2012-01-15'),(9,1,'2015-09-01'),
(10,4,'2018-04-15'),(11,1,'2014-11-01'),(12,5,'2019-02-18'),  -- fully remote
(13,4,'2020-08-01'),(14,1,'2013-03-10'),(15,1,'2016-07-20'),
(16,4,'2015-02-01'),(17,4,'2017-06-12'),(18,4,'2021-03-01'),
(19,4,'2016-09-01'),(20,5,'2019-11-01'),  -- fully remote
(21,1,'2018-01-15'),(22,4,'2020-05-10'),(23,1,'2015-08-01'),
(24,1,'2019-04-01'),(25,4,'2017-11-15'),(26,1,'2018-06-01'),
(27,1,'2021-09-01'),(28,1,'2016-03-01'),(29,4,'2020-07-01'),
(30,1,'2017-05-10'),(31,1,'2015-10-01'),(32,4,'2019-08-12'),
(33,1,'2017-02-01'),(34,4,'2020-11-01'),
-- New Cairo branch
(35,1,'2016-06-01'),(36,1,'2018-09-15'),(37,4,'2017-01-20'),
(38,1,'2021-04-01'),(39,1,'2019-07-10'),(40,4,'2016-06-01'),
(41,4,'2019-10-01'),(42,1,'2021-02-01'),(43,1,'2017-06-01'),
(44,1,'2020-09-01'),(45,4,'2018-11-01'),(46,1,'2016-06-01'),
(47,1,'2017-03-01'),(48,1,'2021-06-01'),(49,4,'2019-09-01'),
(50,4,'2020-01-15');


-- ============================================================
-- DATA: leave_types
-- ============================================================
INSERT INTO leave_types (type_name, max_days_per_year, is_paid) VALUES
('Annual Leave',    21,  TRUE),
('Sick Leave',      14,  TRUE),
('Emergency Leave',  3,  TRUE),
('Maternity Leave', 90,  TRUE),
('Paternity Leave',  7,  TRUE),
('Unpaid Leave',    30,  FALSE),
('Study Leave',     10,  TRUE);


-- ============================================================
-- DATA: attendance — April 2025
--   Includes both RFID on-site and system (WFH) records
-- ============================================================
INSERT INTO attendance (employee_id, card_uid, scan_time, scan_type, reader_location, scan_source, attendance_type, status, branch_id) VALUES
-- April 1 — Cairo HQ
(1,'UNF-HQ-001','2025-04-01 08:58:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(1,'UNF-HQ-001','2025-04-01 17:10:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(2,'UNF-HQ-002','2025-04-01 09:02:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(2,'UNF-HQ-002','2025-04-01 17:30:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(4,'UNF-HQ-004','2025-04-01 08:55:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(4,'UNF-HQ-004','2025-04-01 17:05:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(5,'UNF-HQ-005','2025-04-01 09:20:00','Check-In','HQ Main Entrance','RFID','On-Site','Late',1),
(5,'UNF-HQ-005','2025-04-01 17:00:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
-- WFH log-ins (System)
(12,NULL,'2025-04-01 09:05:00','Check-In','VPN / Remote System','System','Work-From-Home','On Time',1),
(12,NULL,'2025-04-01 17:03:00','Check-Out','VPN / Remote System','System','Work-From-Home','On Time',1),
(20,NULL,'2025-04-01 09:00:00','Check-In','VPN / Remote System','System','Work-From-Home','On Time',1),
(20,NULL,'2025-04-01 17:00:00','Check-Out','VPN / Remote System','System','Work-From-Home','On Time',1),
-- Hybrid employees — WFH day
(6,NULL,'2025-04-01 09:10:00','Check-In','VPN / Remote System','System','Work-From-Home','On Time',1),
(6,NULL,'2025-04-01 17:05:00','Check-Out','VPN / Remote System','System','Work-From-Home','On Time',1),

-- April 1 — New Cairo Branch
(35,'UNF-NC-001','2025-04-01 08:57:00','Check-In','NC Main Entrance','RFID','On-Site','On Time',2),
(35,'UNF-NC-001','2025-04-01 17:00:00','Check-Out','NC Main Entrance','RFID','On-Site','On Time',2),
(40,'UNF-NC-006','2025-04-01 09:00:00','Check-In','NC Main Entrance','RFID','On-Site','On Time',2),
(40,'UNF-NC-006','2025-04-01 17:00:00','Check-Out','NC Main Entrance','RFID','On-Site','On Time',2),

-- April 2
(1,'UNF-HQ-001','2025-04-02 09:00:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(1,'UNF-HQ-001','2025-04-02 17:00:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(8,'UNF-HQ-008','2025-04-02 08:50:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(8,'UNF-HQ-008','2025-04-02 17:15:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(16,'UNF-HQ-016','2025-04-02 09:30:00','Check-In','HQ Main Entrance','RFID','On-Site','Late',1),
(16,'UNF-HQ-016','2025-04-02 17:10:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(12,NULL,'2025-04-02 09:00:00','Check-In','VPN / Remote System','System','Work-From-Home','On Time',1),
(12,NULL,'2025-04-02 17:00:00','Check-Out','VPN / Remote System','System','Work-From-Home','On Time',1),
(36,'UNF-NC-002','2025-04-02 09:05:00','Check-In','NC Main Entrance','RFID','On-Site','On Time',2),
(36,'UNF-NC-002','2025-04-02 17:00:00','Check-Out','NC Main Entrance','RFID','On-Site','On Time',2),

-- April 3
(4,'UNF-HQ-004','2025-04-03 08:55:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(4,'UNF-HQ-004','2025-04-03 18:00:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(23,'UNF-HQ-023','2025-04-03 09:10:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(23,'UNF-HQ-023','2025-04-03 15:45:00','Check-Out','HQ Main Entrance','RFID','On-Site','Early Leave',1),
(20,NULL,'2025-04-03 09:00:00','Check-In','VPN / Remote System','System','Work-From-Home','On Time',1),
(20,NULL,'2025-04-03 17:00:00','Check-Out','VPN / Remote System','System','Work-From-Home','On Time',1),
(37,'UNF-NC-003','2025-04-03 09:00:00','Check-In','NC Main Entrance','RFID','On-Site','On Time',2),
(37,'UNF-NC-003','2025-04-03 17:00:00','Check-Out','NC Main Entrance','RFID','On-Site','On Time',2),

-- April 6
(1,'UNF-HQ-001','2025-04-06 09:01:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(1,'UNF-HQ-001','2025-04-06 17:00:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(11,'UNF-HQ-011','2025-04-06 08:50:00','Check-In','HQ Server Room','RFID','On-Site','On Time',1),
(11,'UNF-HQ-011','2025-04-06 17:00:00','Check-Out','HQ Server Room','RFID','On-Site','On Time',1),
(12,NULL,'2025-04-06 09:00:00','Check-In','VPN / Remote System','System','Work-From-Home','On Time',1),
(12,NULL,'2025-04-06 17:00:00','Check-Out','VPN / Remote System','System','Work-From-Home','On Time',1),
-- Hybrid Layla comes in this day
(20,'UNF-HQ-020','2025-04-06 09:00:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(20,'UNF-HQ-020','2025-04-06 17:00:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(43,'UNF-NC-009','2025-04-06 09:00:00','Check-In','NC Main Entrance','RFID','On-Site','On Time',2),
(43,'UNF-NC-009','2025-04-06 17:05:00','Check-Out','NC Main Entrance','RFID','On-Site','On Time',2),

-- April 7
(2,'UNF-HQ-002','2025-04-07 09:00:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(2,'UNF-HQ-002','2025-04-07 17:00:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(19,'UNF-HQ-019','2025-04-07 09:15:00','Check-In','HQ Main Entrance','RFID','On-Site','Late',1),
(19,'UNF-HQ-019','2025-04-07 17:00:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(20,NULL,'2025-04-07 09:00:00','Check-In','VPN / Remote System','System','Work-From-Home','On Time',1),
(20,NULL,'2025-04-07 17:00:00','Check-Out','VPN / Remote System','System','Work-From-Home','On Time',1),
(41,'UNF-NC-007','2025-04-07 09:00:00','Check-In','NC Main Entrance','RFID','On-Site','On Time',2),
(41,'UNF-NC-007','2025-04-07 17:00:00','Check-Out','NC Main Entrance','RFID','On-Site','On Time',2),

-- April 8
(8,'UNF-HQ-008','2025-04-08 09:00:00','Check-In','HQ Main Entrance','RFID','On-Site','On Time',1),
(8,'UNF-HQ-008','2025-04-08 17:30:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(33,'UNF-HQ-033','2025-04-08 09:25:00','Check-In','HQ Main Entrance','RFID','On-Site','Late',1),
(33,'UNF-HQ-033','2025-04-08 17:00:00','Check-Out','HQ Main Entrance','RFID','On-Site','On Time',1),
(12,NULL,'2025-04-08 09:00:00','Check-In','VPN / Remote System','System','Work-From-Home','On Time',1),
(12,NULL,'2025-04-08 17:00:00','Check-Out','VPN / Remote System','System','Work-From-Home','On Time',1),
(44,'UNF-NC-010','2025-04-08 09:00:00','Check-In','NC Main Entrance','RFID','On-Site','On Time',2),
(44,'UNF-NC-010','2025-04-08 17:00:00','Check-Out','NC Main Entrance','RFID','On-Site','On Time',2);


-- ============================================================
-- DATA: work_from_home_requests
-- ============================================================
INSERT INTO work_from_home_requests (employee_id, request_date, reason, status, reviewed_by) VALUES
(6,  '2025-04-01', 'Weekly WFH day',                         'Approved', 4),
(5,  '2025-04-03', 'Doctor appointment in afternoon',         'Approved', 4),
(18, '2025-04-07', 'Urgent personal matter',                  'Approved', 16),
(10, '2025-04-10', 'Working on quarterly report remotely',    'Approved', 8),
(34, '2025-04-14', 'System access issues at branch',          'Pending',  NULL),
(41, '2025-04-15', 'Personal errand — need flexible hours',   'Approved', 35),
(29, '2025-04-21', 'Weekly WFH day',                          'Approved', 28),
(45, '2025-04-22', 'Valuation fieldwork from home office',    'Approved', 35);


-- ============================================================
-- DATA: leave_requests
-- ============================================================
INSERT INTO leave_requests (employee_id, leave_type_id, start_date, end_date, total_days, reason, status, reviewed_by) VALUES
(7,  1, '2025-04-14','2025-04-18', 5,  'Family vacation',                       'Approved', 4),
(13, 2, '2025-04-09','2025-04-10', 2,  'Flu and fever',                         'Approved', 4),
(22, 1, '2025-05-01','2025-05-07', 5,  'Personal travel',                       'Pending',  NULL),
(27, 4, '2025-03-01','2025-05-29',90,  'Maternity leave',                       'Approved', 4),
(18, 3, '2025-04-03','2025-04-03', 1,  'Family emergency',                      'Approved', 4),
(34, 2, '2025-04-21','2025-04-23', 3,  'Medical procedure recovery',            'Approved', 4),
(38, 1, '2025-05-10','2025-05-14', 5,  'Annual holiday',                        'Pending',  NULL),
(48, 1, '2025-06-01','2025-06-05', 5,  'Graduation trip',                       'Pending',  NULL),
(32, 6, '2025-04-28','2025-05-02', 5,  'Unpaid personal leave',                 'Rejected', 31),
(10, 2, '2025-04-22','2025-04-24', 3,  'Back pain, doctor recommendation',      'Approved', 8),
(44, 5, '2025-04-20','2025-04-26', 5,  'Paternity leave — newborn',             'Approved', 35);


-- ============================================================
-- DATA: payroll — March 2025 (all 50 employees)
-- ============================================================
INSERT INTO payroll (employee_id, month, year, base_salary, overtime_hours, overtime_pay, deductions, net_salary, paid_on, status) VALUES
(1, 3,2025,85000.00,0,0,     2125.00,82875.00,'2025-03-31','Paid'),
(2, 3,2025,72000.00,0,0,     1800.00,70200.00,'2025-03-31','Paid'),
(3, 3,2025,65000.00,2,541.67,1625.00,63916.67,'2025-03-31','Paid'),
(4, 3,2025,35000.00,0,0,      875.00,34125.00,'2025-03-31','Paid'),
(5, 3,2025,22000.00,0,0,      550.00,21450.00,'2025-03-31','Paid'),
(6, 3,2025,13500.00,0,0,      337.50,13162.50,'2025-03-31','Paid'),
(7, 3,2025,11000.00,0,0,      275.00,10725.00,'2025-03-31','Paid'),
(8, 3,2025,68000.00,0,0,     1700.00,66300.00,'2025-03-31','Paid'),
(9, 3,2025,30000.00,0,0,      750.00,29250.00,'2025-03-31','Paid'),
(10,3,2025,18500.00,0,0,      462.50,18037.50,'2025-03-31','Paid'),
(11,3,2025,40000.00,4,666.67,1000.00,39666.67,'2025-03-31','Paid'),
(12,3,2025,25000.00,0,0,      625.00,24375.00,'2025-03-31','Paid'),
(13,3,2025,18000.00,2,150.00, 450.00,17700.00,'2025-03-31','Paid'),
(14,3,2025,58000.00,0,0,     1450.00,56550.00,'2025-03-31','Paid'),
(15,3,2025,32000.00,0,0,      800.00,31200.00,'2025-03-31','Paid'),
(16,3,2025,52000.00,0,0,     1300.00,50700.00,'2025-03-31','Paid'),
(17,3,2025,38000.00,2,316.67, 950.00,37366.67,'2025-03-31','Paid'),
(18,3,2025,22000.00,0,0,      550.00,21450.00,'2025-03-31','Paid'),
(19,3,2025,45000.00,3,562.50,1125.00,44437.50,'2025-03-31','Paid'),
(20,3,2025,28000.00,0,0,      700.00,27300.00,'2025-03-31','Paid'),
(21,3,2025,30000.00,0,0,      750.00,29250.00,'2025-03-31','Paid'),
(22,3,2025,18000.00,0,0,      450.00,17550.00,'2025-03-31','Paid'),
(23,3,2025,42000.00,0,0,     1050.00,40950.00,'2025-03-31','Paid'),
(24,3,2025,20000.00,0,0,      500.00,19500.00,'2025-03-31','Paid'),
(25,3,2025,32000.00,2,266.67, 800.00,31466.67,'2025-03-31','Paid'),
(26,3,2025,28000.00,0,0,      700.00,27300.00,'2025-03-31','Paid'),
(27,3,2025,17000.00,0,0,        0.00,17000.00,'2025-03-31','Paid'),  -- maternity, no deduction
(28,3,2025,38000.00,0,0,      950.00,37050.00,'2025-03-31','Paid'),
(29,3,2025,19000.00,0,0,      475.00,18525.00,'2025-03-31','Paid'),
(30,3,2025,33000.00,0,0,      825.00,32175.00,'2025-03-31','Paid'),
(31,3,2025,40000.00,0,0,     1000.00,39000.00,'2025-03-31','Paid'),
(32,3,2025,22000.00,0,0,      550.00,21450.00,'2025-03-31','Paid'),
(33,3,2025,30000.00,0,0,      750.00,29250.00,'2025-03-31','Paid'),
(34,3,2025,20000.00,0,0,      500.00,19500.00,'2025-03-31','Paid'),
(35,3,2025,48000.00,0,0,     1200.00,46800.00,'2025-03-31','Paid'),
(36,3,2025,24000.00,2,200.00, 600.00,23600.00,'2025-03-31','Paid'),
(37,3,2025,25000.00,0,0,      625.00,24375.00,'2025-03-31','Paid'),
(38,3,2025,13000.00,0,0,      325.00,12675.00,'2025-03-31','Paid'),
(39,3,2025,20000.00,0,0,      500.00,19500.00,'2025-03-31','Paid'),
(40,3,2025,44000.00,3,550.00,1100.00,43450.00,'2025-03-31','Paid'),
(41,3,2025,26000.00,0,0,      650.00,25350.00,'2025-03-31','Paid'),
(42,3,2025,22000.00,0,0,      550.00,21450.00,'2025-03-31','Paid'),
(43,3,2025,35000.00,0,0,      875.00,34125.00,'2025-03-31','Paid'),
(44,3,2025,19000.00,0,0,      475.00,18525.00,'2025-03-31','Paid'),
(45,3,2025,24000.00,0,0,      600.00,23400.00,'2025-03-31','Paid'),
(46,3,2025,36000.00,0,0,      900.00,35100.00,'2025-03-31','Paid'),
(47,3,2025,32000.00,0,0,      800.00,31200.00,'2025-03-31','Paid'),
(48,3,2025,18000.00,0,0,      450.00,17550.00,'2025-03-31','Paid'),
(49,3,2025,20000.00,2,166.67, 500.00,19666.67,'2025-03-31','Paid'),
(50,3,2025,20000.00,0,0,      500.00,19500.00,'2025-03-31','Paid');


-- ============================================================
-- DATA: rfid_unknown_scans (security events)
-- ============================================================
INSERT INTO rfid_unknown_scans (card_uid, scan_time, reader_location, branch_id, flagged) VALUES
('DEADBEEF01', '2025-04-02 23:14:00', 'HQ Server Room',      1, TRUE),
('CAFEBABE02', '2025-04-06 02:45:00', 'HQ Main Entrance',    1, TRUE),
('UNKNOWN-03', '2025-04-09 11:30:00', 'NC Main Entrance',    2, TRUE),
('TMPCARD-04', '2025-04-10 08:15:00', 'HQ Finance Floor',    1, TRUE);


-- ============================================================
-- VIEWS
-- ============================================================

-- Full employee profile view
CREATE VIEW v_employee_full AS
SELECT
    e.employee_id,
    CONCAT(e.first_name,' ',e.last_name)    AS full_name,
    e.email,
    e.phone,
    b.branch_name                            AS branch,
    b.city                                   AS city,
    d.name                                   AS department,
    d.division                               AS business_line,
    e.job_title,
    e.salary,
    e.hire_date,
    e.status,
    e.work_arrangement,
    e.remote_days_per_week,
    rc.card_uid,
    rc.is_active                             AS card_active
FROM employees e
LEFT JOIN branches b    ON e.branch_id      = b.branch_id
LEFT JOIN departments d ON e.department_id  = d.department_id
LEFT JOIN rfid_cards rc ON e.employee_id    = rc.employee_id;


-- Daily attendance view
CREATE VIEW v_attendance_daily AS
SELECT
    a.attendance_id,
    CONCAT(e.first_name,' ',e.last_name)  AS full_name,
    b.branch_name                          AS branch,
    d.name                                 AS department,
    DATE(a.scan_time)                      AS work_date,
    a.scan_type,
    TIME(a.scan_time)                      AS scan_time,
    a.attendance_type,
    a.scan_source,
    a.reader_location,
    a.status
FROM attendance a
JOIN employees e  ON a.employee_id   = e.employee_id
JOIN branches  b  ON a.branch_id     = b.branch_id
JOIN departments d ON e.department_id = d.department_id
ORDER BY a.scan_time DESC;


-- Monthly attendance summary per employee
CREATE VIEW v_monthly_attendance_summary AS
SELECT
    e.employee_id,
    CONCAT(e.first_name,' ',e.last_name)            AS full_name,
    b.branch_name                                    AS branch,
    d.name                                           AS department,
    e.work_arrangement,
    COUNT(DISTINCT CASE WHEN a.attendance_type='On-Site'        AND a.scan_type='Check-In' THEN DATE(a.scan_time) END) AS days_on_site,
    COUNT(DISTINCT CASE WHEN a.attendance_type='Work-From-Home' AND a.scan_type='Check-In' THEN DATE(a.scan_time) END) AS days_wfh,
    COUNT(DISTINCT DATE(a.scan_time))               AS total_days_present,
    SUM(CASE WHEN a.status='Late'        AND a.scan_type='Check-In'  THEN 1 ELSE 0 END) AS late_arrivals,
    SUM(CASE WHEN a.status='Early Leave' AND a.scan_type='Check-Out' THEN 1 ELSE 0 END) AS early_leaves
FROM employees e
LEFT JOIN attendance a  ON e.employee_id   = a.employee_id
JOIN branches b          ON e.branch_id     = b.branch_id
JOIN departments d        ON e.department_id = d.department_id
WHERE MONTH(a.scan_time) = MONTH(CURDATE())
  AND YEAR(a.scan_time)  = YEAR(CURDATE())
GROUP BY e.employee_id, full_name, branch, department, e.work_arrangement;


-- WFH vs On-Site breakdown per branch
CREATE VIEW v_branch_wfh_summary AS
SELECT
    b.branch_name,
    b.city,
    e.work_arrangement,
    COUNT(DISTINCT e.employee_id)                   AS employee_count,
    ROUND(AVG(e.remote_days_per_week),1)            AS avg_remote_days_per_week
FROM employees e
JOIN branches b ON e.branch_id = b.branch_id
WHERE e.status = 'Active'
GROUP BY b.branch_name, b.city, e.work_arrangement;


-- On-site employees who took a WFH day this month
CREATE VIEW v_onsite_wfh_exceptions AS
SELECT
    CONCAT(e.first_name,' ',e.last_name) AS full_name,
    b.branch_name,
    d.name                               AS department,
    e.work_arrangement,
    w.request_date,
    w.reason,
    w.status                             AS wfh_approval
FROM work_from_home_requests w
JOIN employees e    ON w.employee_id   = e.employee_id
JOIN branches b     ON e.branch_id     = b.branch_id
JOIN departments d  ON e.department_id = d.department_id
WHERE e.work_arrangement = 'On-Site'
  AND w.status = 'Approved';


-- Remote/Hybrid employees who came in physically
CREATE VIEW v_remote_onsite_visits AS
SELECT
    CONCAT(e.first_name,' ',e.last_name) AS full_name,
    b.branch_name,
    d.name                               AS department,
    e.work_arrangement,
    DATE(a.scan_time)                    AS visit_date,
    a.reader_location
FROM attendance a
JOIN employees e    ON a.employee_id   = e.employee_id
JOIN branches b     ON a.branch_id     = b.branch_id
JOIN departments d  ON e.department_id = d.department_id
WHERE a.attendance_type = 'On-Site'
  AND e.work_arrangement IN ('Remote','Hybrid')
  AND a.scan_type = 'Check-In';


-- Leave summary with excuse/reason detail
CREATE VIEW v_leave_summary AS
SELECT
    CONCAT(e.first_name,' ',e.last_name)        AS employee_name,
    b.branch_name,
    d.name                                       AS department,
    lt.type_name                                 AS leave_type,
    lr.start_date,
    lr.end_date,
    lr.total_days,
    lr.reason,
    lr.status                                    AS approval_status,
    CONCAT(r.first_name,' ',r.last_name)         AS reviewed_by
FROM leave_requests lr
JOIN employees e    ON lr.employee_id   = e.employee_id
JOIN branches b     ON e.branch_id      = b.branch_id
JOIN departments d  ON e.department_id  = d.department_id
JOIN leave_types lt ON lr.leave_type_id = lt.leave_type_id
LEFT JOIN employees r ON lr.reviewed_by = r.employee_id;


-- ============================================================
-- TRIGGERS
-- ============================================================

-- TRIGGER 1: Auto-calculate total_days on leave_requests INSERT
DELIMITER $$
CREATE TRIGGER trg_leave_calc_days
BEFORE INSERT ON leave_requests
FOR EACH ROW
BEGIN
    IF NEW.total_days IS NULL THEN
        SET NEW.total_days = DATEDIFF(NEW.end_date, NEW.start_date) + 1;
    END IF;
END$$
DELIMITER ;


-- TRIGGER 2: Auto-populate base_salary and net_salary in payroll from employees
DELIMITER $$
CREATE TRIGGER trg_payroll_default_salary
BEFORE INSERT ON payroll
FOR EACH ROW
BEGIN
    DECLARE v_salary DECIMAL(10,2);
    IF NEW.base_salary IS NULL THEN
        SELECT salary INTO v_salary
        FROM employees
        WHERE employee_id = NEW.employee_id;
        SET NEW.base_salary = v_salary;
    END IF;
    IF NEW.net_salary IS NULL THEN
        SET NEW.net_salary = NEW.base_salary + IFNULL(NEW.overtime_pay,0) - IFNULL(NEW.deductions,0);
    END IF;
END$$
DELIMITER ;


-- TRIGGER 3: Deactivate RFID card when employee status set to Inactive
DELIMITER $$
CREATE TRIGGER trg_deactivate_card_on_inactive
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    IF NEW.status = 'Inactive' AND OLD.status != 'Inactive' THEN
        UPDATE rfid_cards
        SET    is_active = FALSE
        WHERE  employee_id = NEW.employee_id;
    END IF;
END$$
DELIMITER ;


-- TRIGGER 4: Prevent attendance insert for an inactive employee
DELIMITER $$
CREATE TRIGGER trg_block_inactive_attendance
BEFORE INSERT ON attendance
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status
    FROM   employees
    WHERE  employee_id = NEW.employee_id;
    IF v_status = 'Inactive' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot record attendance for an inactive employee.';
    END IF;
END$$
DELIMITER ;


-- ============================================================
-- SQL QUERIES — JOINs, Aggregation, Projection, Subqueries
-- ============================================================

-- ── 1. PROJECTION: Full employee directory (selected columns only) ───────────
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    e.job_title,
    e.employment_type,
    e.work_arrangement,
    d.name        AS department,
    b.branch_name AS branch
FROM  employees   e
JOIN  departments d ON e.department_id = d.department_id
JOIN  branches    b ON e.branch_id     = b.branch_id
WHERE e.status = 'Active'
ORDER BY b.branch_name, d.name, e.last_name;


-- ── 2. JOIN + AGGREGATION: Headcount per department per branch ───────────────
SELECT
    b.branch_name,
    d.division,
    d.name              AS department,
    COUNT(e.employee_id) AS headcount,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM  departments d
JOIN  branches    b ON d.branch_id     = b.branch_id
LEFT  JOIN employees e ON e.department_id = d.department_id
                       AND e.status = 'Active'
GROUP BY b.branch_name, d.division, d.name
ORDER BY b.branch_name, headcount DESC;


-- ── 3. JOIN + AGGREGATION: Monthly payroll cost per branch ──────────────────
SELECT
    b.branch_name,
    p.month,
    p.year,
    SUM(p.base_salary)   AS total_base,
    SUM(p.overtime_pay)  AS total_overtime,
    SUM(p.deductions)    AS total_deductions,
    SUM(p.net_salary)    AS total_net_payout,
    COUNT(p.employee_id) AS employees_paid
FROM  payroll  p
JOIN  employees e ON p.employee_id = e.employee_id
JOIN  branches  b ON e.branch_id   = b.branch_id
GROUP BY b.branch_name, p.year, p.month
ORDER BY p.year DESC, p.month DESC, b.branch_name;


-- ── 4. SUBQUERY: Employees earning above their department's average salary ───
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    e.job_title,
    d.name   AS department,
    e.salary AS employee_salary,
    (SELECT ROUND(AVG(e2.salary), 2)
     FROM   employees e2
     WHERE  e2.department_id = e.department_id
       AND  e2.status = 'Active') AS dept_avg_salary
FROM  employees   e
JOIN  departments d ON e.department_id = d.department_id
WHERE e.status = 'Active'
  AND e.salary > (
        SELECT AVG(e3.salary)
        FROM   employees e3
        WHERE  e3.department_id = e.department_id
          AND  e3.status = 'Active'
  )
ORDER BY d.name, e.salary DESC;


-- ── 5. SUBQUERY: Employees who have NEVER taken any leave ────────────────────
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    e.hire_date,
    b.branch_name,
    d.name AS department
FROM  employees   e
JOIN  branches    b ON e.branch_id     = b.branch_id
JOIN  departments d ON e.department_id = d.department_id
WHERE e.status = 'Active'
  AND e.employee_id NOT IN (
        SELECT DISTINCT employee_id
        FROM   leave_requests
        WHERE  status = 'Approved'
  )
ORDER BY e.hire_date;


-- ── 6. JOIN + AGGREGATION: Late arrival count per employee (April 2025) ──────
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    b.branch_name,
    d.name                                  AS department,
    COUNT(*)                                AS late_arrivals
FROM  attendance  a
JOIN  employees   e ON a.employee_id   = e.employee_id
JOIN  branches    b ON e.branch_id     = b.branch_id
JOIN  departments d ON e.department_id = d.department_id
WHERE a.scan_type = 'Check-In'
  AND a.status    = 'Late'
  AND YEAR(a.scan_time)  = 2025
  AND MONTH(a.scan_time) = 4
GROUP BY e.employee_id, full_name, b.branch_name, d.name
ORDER BY late_arrivals DESC;


-- ── 7. JOIN + SUBQUERY: Departments with no manager assigned ─────────────────
SELECT
    d.department_id,
    d.name       AS department,
    d.division,
    b.branch_name
FROM  departments d
JOIN  branches    b ON d.branch_id = b.branch_id
WHERE d.manager_id IS NULL
   OR d.manager_id NOT IN (
        SELECT employee_id FROM employees WHERE status = 'Active'
  )
ORDER BY b.branch_name, d.division;


-- ── 8. AGGREGATION + JOIN: Leave usage vs entitlement per type ───────────────
SELECT
    lt.type_name,
    lt.max_days_per_year      AS max_entitlement,
    lt.is_paid,
    COUNT(lr.leave_id)        AS total_requests,
    SUM(lr.total_days)        AS total_days_taken,
    ROUND(AVG(lr.total_days), 1) AS avg_days_per_request
FROM  leave_types   lt
LEFT  JOIN leave_requests lr ON lr.leave_type_id = lt.leave_type_id
                              AND lr.status = 'Approved'
GROUP BY lt.leave_type_id, lt.type_name, lt.max_days_per_year, lt.is_paid
ORDER BY total_days_taken DESC;


-- ── 9. SUBQUERY + JOIN: Employees on approved leave today ────────────────────
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    b.branch_name,
    lt.type_name  AS leave_type,
    lr.start_date,
    lr.end_date,
    lr.total_days
FROM  leave_requests lr
JOIN  employees  e  ON lr.employee_id   = e.employee_id
JOIN  branches   b  ON e.branch_id      = b.branch_id
JOIN  leave_types lt ON lr.leave_type_id = lt.leave_type_id
WHERE lr.status = 'Approved'
  AND CURDATE() BETWEEN lr.start_date AND lr.end_date;


-- ── 10. SIMULATE RFID SCAN (stored procedure call) ──────────────────────────
-- CALL sp_process_rfid_scan('UNF-HQ-001', 'HQ Main Entrance', 1);


-- ============================================================
-- END OF SCRIPT — UNIFINA GROUP DATABASE v1.1
-- ============================================================
