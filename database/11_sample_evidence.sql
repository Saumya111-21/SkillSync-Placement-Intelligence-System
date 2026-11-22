-- SkillSync SAMPLE DATA, part 6: projects, certifications, assessments
-- ALL DATA IN THE SAMPLE FILES IS SYNTHETIC (invented).
-- Deliberate test cases for the evidence view:
--   Kabir: Excel declared at level 4 with NO evidence at all
--   Diya : two SQL assessments (55 then 78): the latest one counts
--   Aarav: Python assessment 62 (level 2) below his declared level 3

BEGIN;

INSERT INTO student_project (student_id, title, description, start_date, end_date)
SELECT st.student_id, v.title, v.descr, v.sd, v.ed
FROM (VALUES
    ('CS23-001', 'Library Management API',
     'REST API for a college library built with Flask and PostgreSQL.',
     DATE '2025-08-01', DATE '2025-11-15'),
    ('CS23-001', 'Task Tracker CLI',
     'Command line task tracker in Python, tracked with Git.',
     DATE '2025-01-10', DATE '2025-02-20'),
    ('DS23-002', 'Retail Sales Dashboard',
     'Interactive sales dashboard with Power BI over SQL data.',
     DATE '2025-09-01', DATE '2025-12-01'),
    ('DS23-002', 'Customer Churn Study',
     'Statistics and basic machine learning on a churn dataset.',
     DATE '2025-03-01', DATE '2025-05-20'),
    ('IT23-003', 'Student Marks Reporting',
     'Reports on student marks using SQL and Tableau.',
     DATE '2025-07-15', DATE '2025-10-10'),
    ('DS23-004', 'House Price Prediction',
     'Cleaned data and trained a regression model in Python.',
     DATE '2025-08-10', DATE '2025-11-25'),
    ('DS23-004', 'Survey Analysis in R',
     'Statistical analysis and charts for a campus survey.',
     DATE '2025-02-01', DATE '2025-04-15'),
    ('CS23-005', 'Inventory Manager',
     'Inventory tool in Java with SQL storage; scripts in Python.',
     DATE '2025-06-01', DATE '2025-09-30'),
    ('EC23-006', 'Sensor Data Logger',
     'C++ firmware plus a Python script to log sensor data.',
     DATE '2025-05-01', DATE '2025-08-15'),
    ('CS24-008', 'Portfolio Website',
     'Responsive portfolio site built with React and Node.js.',
     DATE '2026-01-10', DATE '2026-04-30'),
    ('IT23-009', 'Event Registration Page',
     'Web page for event sign-ups with HTML, CSS and JavaScript.',
     DATE '2025-10-01', DATE '2025-12-20'),
    ('DS24-010', 'Cricket Stats Dashboard',
     'Tableau dashboard of match statistics.',
     DATE '2026-02-01', DATE '2026-04-10')
) AS v(enr, title, descr, sd, ed)
JOIN student st ON st.enrollment_no = v.enr;

INSERT INTO project_skill (project_id, skill_id)
SELECT p.project_id, sk.skill_id
FROM (VALUES
    ('Library Management API',     'Python'),
    ('Library Management API',     'Flask'),
    ('Library Management API',     'PostgreSQL'),
    ('Library Management API',     'SQL'),
    ('Task Tracker CLI',           'Python'),
    ('Task Tracker CLI',           'Git'),
    ('Retail Sales Dashboard',     'Power BI'),
    ('Retail Sales Dashboard',     'SQL'),
    ('Retail Sales Dashboard',     'Data Visualization'),
    ('Customer Churn Study',       'Statistics'),
    ('Customer Churn Study',       'Machine Learning Basics'),
    ('Customer Churn Study',       'Python'),
    ('Student Marks Reporting',    'SQL'),
    ('Student Marks Reporting',    'Tableau'),
    ('House Price Prediction',     'Python'),
    ('House Price Prediction',     'Data Cleaning'),
    ('House Price Prediction',     'Machine Learning Basics'),
    ('Survey Analysis in R',       'R'),
    ('Survey Analysis in R',       'Statistics'),
    ('Inventory Manager',          'Java'),
    ('Inventory Manager',          'SQL'),
    ('Inventory Manager',          'Python'),
    ('Sensor Data Logger',         'C++'),
    ('Sensor Data Logger',         'Python'),
    ('Portfolio Website',          'React'),
    ('Portfolio Website',          'Node.js'),
    ('Portfolio Website',          'JavaScript'),
    ('Event Registration Page',    'HTML and CSS'),
    ('Event Registration Page',    'JavaScript'),
    ('Cricket Stats Dashboard',    'Tableau'),
    ('Cricket Stats Dashboard',    'Data Visualization')
) AS v(title, sname)
JOIN student_project p ON p.title = v.title
JOIN skill sk          ON sk.skill_name = v.sname;

INSERT INTO student_certification (student_id, certification_id, issue_date)
SELECT st.student_id, c.certification_id, v.idate
FROM (VALUES
    ('CS23-001', 'Python for Everybody',                           DATE '2025-03-15'),
    ('DS23-002', 'Google Data Analytics Professional Certificate', DATE '2025-06-30'),
    ('DS23-002', 'Microsoft Power BI Data Analyst',                DATE '2025-12-10'),
    ('IT23-003', 'Oracle Database SQL Certified Associate',        DATE '2025-11-05'),
    ('DS23-004', 'IBM Data Science Professional Certificate',      DATE '2025-10-20'),
    ('DS23-004', 'Python for Everybody',                           DATE '2024-12-12'),
    ('CS23-005', 'AWS Cloud Practitioner',                         DATE '2026-01-25'),
    ('CS24-008', 'MongoDB Associate Developer',                    DATE '2026-03-18'),
    ('DS24-010', 'Tableau Desktop Specialist',                     DATE '2026-04-22'),
    ('IT23-003', 'Tableau Desktop Specialist',                     DATE '2025-09-14')
) AS v(enr, cname, idate)
JOIN student st       ON st.enrollment_no = v.enr
JOIN certification c  ON c.certification_name = v.cname;

INSERT INTO skill_assessment (student_id, skill_id, score_percent, taken_at)
SELECT st.student_id, sk.skill_id, v.score, v.at
FROM (VALUES
    ('CS23-001', 'Python',     62, TIMESTAMPTZ '2026-02-10 10:00+05:30'),
    ('CS23-001', 'SQL',        58, TIMESTAMPTZ '2026-02-12 11:00+05:30'),
    ('DS23-002', 'SQL',        55, TIMESTAMPTZ '2026-01-15 10:00+05:30'),
    ('DS23-002', 'SQL',        78, TIMESTAMPTZ '2026-04-20 10:00+05:30'),
    ('DS23-002', 'Excel',      82, TIMESTAMPTZ '2026-03-05 14:00+05:30'),
    ('DS23-002', 'Statistics', 70, TIMESTAMPTZ '2026-03-20 15:00+05:30'),
    ('IT23-003', 'SQL',        74, TIMESTAMPTZ '2026-02-25 09:30+05:30'),
    ('DS23-004', 'Python',     91, TIMESTAMPTZ '2026-03-01 10:00+05:30'),
    ('DS23-004', 'Statistics', 76, TIMESTAMPTZ '2026-03-10 10:00+05:30'),
    ('DS23-004', 'Machine Learning Basics', 68, TIMESTAMPTZ '2026-04-02 10:00+05:30'),
    ('CS23-005', 'Java',       66, TIMESTAMPTZ '2026-02-18 16:00+05:30'),
    ('CS24-008', 'JavaScript', 72, TIMESTAMPTZ '2026-04-05 11:30+05:30'),
    ('DS24-010', 'Excel',      80, TIMESTAMPTZ '2026-05-02 10:00+05:30'),
    ('EC23-006', 'C++',        69, TIMESTAMPTZ '2026-03-14 12:00+05:30')
) AS v(enr, sname, score, at)
JOIN student st ON st.enrollment_no = v.enr
JOIN skill sk   ON sk.skill_name    = v.sname;

COMMIT;