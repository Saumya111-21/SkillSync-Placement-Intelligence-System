-- SkillSync SAMPLE DATA, part 4: students and semester grades
-- ALL DATA IN THE SAMPLE FILES IS SYNTHETIC (invented). The names, phone
-- numbers and grades are made up. password_hash is a placeholder, not a hash.

BEGIN;

INSERT INTO user_account (email, password_hash, role) VALUES
    ('aarav.sharma@example.org',    'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('diya.patel@example.org',      'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('kabir.malhotra@example.org',  'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('ananya.reddy@example.org',    'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('rahul.nair@example.org',      'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('priya.menon@example.org',     'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('sahil.gupta@example.org',     'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('tara.bose@example.org',       'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('yash.choudhary@example.org',  'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student'),
    ('zoya.khan@example.org',       'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'student');

INSERT INTO student (user_id, course_id, enrollment_no, full_name, phone, admission_year)
SELECT u.user_id, c.course_id, v.enr, v.fname, v.phone, v.yr
FROM (VALUES
    ('aarav.sharma@example.org',   'Aarav Sharma',   'B.Tech CSE',                'CS23-001', '9810000001', 2023),
    ('diya.patel@example.org',     'Diya Patel',     'B.Tech CSE (Data Science)', 'DS23-002', '9810000002', 2023),
    ('kabir.malhotra@example.org', 'Kabir Malhotra', 'B.Tech IT',                 'IT23-003', NULL,         2023),
    ('ananya.reddy@example.org',   'Ananya Reddy',   'B.Tech CSE (Data Science)', 'DS23-004', '9810000004', 2023),
    ('rahul.nair@example.org',     'Rahul Nair',     'B.Tech CSE',                'CS23-005', '9810000005', 2023),
    ('priya.menon@example.org',    'Priya Menon',    'B.Tech ECE',                'EC23-006', NULL,         2023),
    ('sahil.gupta@example.org',    'Sahil Gupta',    'B.Tech Mechanical',         'ME24-007', '9810000007', 2024),
    ('tara.bose@example.org',      'Tara Bose',      'B.Tech CSE',                'CS24-008', '9810000008', 2024),
    ('yash.choudhary@example.org', 'Yash Choudhary', 'B.Tech IT',                 'IT23-009', NULL,         2023),
    ('zoya.khan@example.org',      'Zoya Khan',      'B.Tech CSE (Data Science)', 'DS24-010', '9810000010', 2024)
) AS v(email, fname, cname, enr, phone, yr)
JOIN user_account u ON u.email = v.email
JOIN course c       ON c.course_name = v.cname;

-- Semester grades: the position in the list is the semester number.
INSERT INTO academic_record (student_id, semester_no, sgpa)
SELECT s.student_id, u.ord, u.sg
FROM (VALUES
    ('CS23-001', ARRAY[7.8, 8.0, 8.2, 8.1, 8.4, 8.5]),
    ('DS23-002', ARRAY[8.6, 8.8, 9.0, 8.9, 9.1, 9.2]),
    ('IT23-003', ARRAY[6.9, 7.1, 7.0, 7.3, 7.4, 7.5]),
    ('DS23-004', ARRAY[8.2, 8.4, 8.7, 8.5, 8.9, 9.0]),
    ('CS23-005', ARRAY[7.2, 7.0, 7.4, 7.6, 7.5, 7.8]),
    ('EC23-006', ARRAY[7.5, 7.7, 7.6, 7.9, 8.0, 8.1]),
    ('ME24-007', ARRAY[6.4, 6.6, 6.8, 7.0]),
    ('CS24-008', ARRAY[8.0, 8.3, 8.5, 8.6]),
    ('IT23-009', ARRAY[6.2, 6.5, 6.4, 6.8, 6.9, 7.0]),
    ('DS24-010', ARRAY[8.8, 9.0, 9.1, 9.2])
) AS v(enr, sgpas)
JOIN student s ON s.enrollment_no = v.enr
CROSS JOIN LATERAL unnest(v.sgpas::numeric[]) WITH ORDINALITY AS u(sg, ord);

COMMIT;