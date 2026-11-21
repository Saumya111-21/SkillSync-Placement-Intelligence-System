-- SkillSync trigger tests, set 1 (account role rules)
-- T6 to T10 must be REFUSED. T11 must be ACCEPTED.
-- Each test sets up its own data and runs inside BEGIN ... ROLLBACK,
-- so nothing is kept.

\echo ''
\echo 'T6: student row linked to a recruiter account  (expect: refused by trigger)'
BEGIN;
INSERT INTO user_account (email, password_hash, role)
VALUES ('t6@example.com', 'x', 'recruiter');
INSERT INTO department (department_name) VALUES ('T6 Dept');
INSERT INTO course (department_id, course_name, duration_years)
SELECT department_id, 'T6 Course', 4 FROM department WHERE department_name = 'T6 Dept';
INSERT INTO student (user_id, course_id, enrollment_no, full_name, admission_year)
SELECT u.user_id, c.course_id, 'T6-ENR', 'T6 Student', 2023
FROM user_account u, course c
WHERE u.email = 't6@example.com' AND c.course_name = 'T6 Course';
ROLLBACK;

\echo ''
\echo 'T7: recruiter row linked to a student account  (expect: refused by trigger)'
BEGIN;
INSERT INTO user_account (email, password_hash, role)
VALUES ('t7@example.com', 'x', 'student');
INSERT INTO company (company_name, industry) VALUES ('T7 Company', 'IT Services');
INSERT INTO recruiter (user_id, company_id, full_name, designation)
SELECT u.user_id, c.company_id, 'T7 Recruiter', 'HR Manager'
FROM user_account u, company c
WHERE u.email = 't7@example.com' AND c.company_name = 'T7 Company';
ROLLBACK;

\echo ''
\echo 'T8: company approved by a student account  (expect: refused by trigger)'
BEGIN;
INSERT INTO user_account (email, password_hash, role)
VALUES ('t8@example.com', 'x', 'student');
INSERT INTO company (company_name, industry, status_id, reviewed_by, reviewed_at)
SELECT 'T8 Company', 'IT Services', 2, user_id, now()
FROM user_account WHERE email = 't8@example.com';
ROLLBACK;

\echo ''
\echo 'T9: job approved by a recruiter account  (expect: refused by trigger)'
BEGIN;
INSERT INTO user_account (email, password_hash, role)
VALUES ('t9@example.com', 'x', 'recruiter');
INSERT INTO company (company_name, industry) VALUES ('T9 Company', 'IT Services');
INSERT INTO recruiter (user_id, company_id, full_name, designation)
SELECT u.user_id, c.company_id, 'T9 Recruiter', 'HR Manager'
FROM user_account u, company c
WHERE u.email = 't9@example.com' AND c.company_name = 'T9 Company';
INSERT INTO job (recruiter_id, title, description, job_type, location,
                 application_deadline, status_id, reviewed_by, reviewed_at)
SELECT r.recruiter_id, 'T9 Job', 'Test job', 'full_time', 'Delhi',
       CURRENT_DATE + 30, 2, r.user_id, now()
FROM recruiter r WHERE r.full_name = 'T9 Recruiter';
ROLLBACK;

\echo ''
\echo 'T10: change the role of an account already used as a student  (expect: refused by trigger)'
BEGIN;
INSERT INTO user_account (email, password_hash, role)
VALUES ('t10@example.com', 'x', 'student');
INSERT INTO department (department_name) VALUES ('T10 Dept');
INSERT INTO course (department_id, course_name, duration_years)
SELECT department_id, 'T10 Course', 4 FROM department WHERE department_name = 'T10 Dept';
INSERT INTO student (user_id, course_id, enrollment_no, full_name, admission_year)
SELECT u.user_id, c.course_id, 'T10-ENR', 'T10 Student', 2023
FROM user_account u, course c
WHERE u.email = 't10@example.com' AND c.course_name = 'T10 Course';
UPDATE user_account SET role = 'admin' WHERE email = 't10@example.com';
ROLLBACK;

\echo ''
\echo 'T11: the same actions done correctly  (expect: every statement ACCEPTED, no ERROR)'
BEGIN;
INSERT INTO user_account (email, password_hash, role) VALUES ('t11a@example.com', 'x', 'admin');
INSERT INTO user_account (email, password_hash, role) VALUES ('t11s@example.com', 'x', 'student');
INSERT INTO user_account (email, password_hash, role) VALUES ('t11r@example.com', 'x', 'recruiter');
INSERT INTO department (department_name) VALUES ('T11 Dept');
INSERT INTO course (department_id, course_name, duration_years)
SELECT department_id, 'T11 Course', 4 FROM department WHERE department_name = 'T11 Dept';
INSERT INTO student (user_id, course_id, enrollment_no, full_name, admission_year)
SELECT u.user_id, c.course_id, 'T11-ENR', 'T11 Student', 2023
FROM user_account u, course c
WHERE u.email = 't11s@example.com' AND c.course_name = 'T11 Course';
INSERT INTO company (company_name, industry, status_id, reviewed_by, reviewed_at)
SELECT 'T11 Company', 'IT Services', 2, user_id, now()
FROM user_account WHERE email = 't11a@example.com';
INSERT INTO recruiter (user_id, company_id, full_name, designation)
SELECT u.user_id, c.company_id, 'T11 Recruiter', 'HR Manager'
FROM user_account u, company c
WHERE u.email = 't11r@example.com' AND c.company_name = 'T11 Company';
ROLLBACK;

\echo ''
\echo 'Done. T6 to T10 should each end in an ERROR. T11 should show only INSERT 0 1 lines.'
