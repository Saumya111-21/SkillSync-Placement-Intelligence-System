-- SkillSync trigger tests, set 2 (matching, applications, placements)
-- Setup runs once. Each test uses a SAVEPOINT: refused tests are undone with
-- ROLLBACK TO SAVEPOINT, accepted steps stay so later tests can use them.
-- The final ROLLBACK removes everything.

BEGIN;

-- ---------- setup ----------
INSERT INTO user_account (email, password_hash, role) VALUES
    ('tr_admin@example.com',    'x', 'admin'),
    ('tr_student@example.com',  'x', 'student'),
    ('tr_student2@example.com', 'x', 'student'),
    ('tr_r1@example.com',       'x', 'recruiter'),
    ('tr_r2@example.com',       'x', 'recruiter');
INSERT INTO department (department_name) VALUES ('TR Dept');
INSERT INTO course (department_id, course_name, duration_years)
SELECT department_id, 'TR Course', 4 FROM department WHERE department_name = 'TR Dept';
INSERT INTO student (user_id, course_id, enrollment_no, full_name, admission_year)
SELECT u.user_id, c.course_id, 'TR-ENR', 'TR Student', 2023
FROM user_account u, course c
WHERE u.email = 'tr_student@example.com' AND c.course_name = 'TR Course';
INSERT INTO company (company_name, industry, status_id, reviewed_by, reviewed_at)
SELECT n, 'IT Services', 2, a.user_id, now()
FROM user_account a, (VALUES ('TR Company A'), ('TR Company B')) AS t(n)
WHERE a.email = 'tr_admin@example.com';
INSERT INTO recruiter (user_id, company_id, full_name, designation)
SELECT u.user_id, c.company_id, 'TR Recruiter A', 'HR'
FROM user_account u, company c
WHERE u.email = 'tr_r1@example.com' AND c.company_name = 'TR Company A';
INSERT INTO recruiter (user_id, company_id, full_name, designation)
SELECT u.user_id, c.company_id, 'TR Recruiter B', 'HR'
FROM user_account u, company c
WHERE u.email = 'tr_r2@example.com' AND c.company_name = 'TR Company B';
INSERT INTO job (recruiter_id, title, description, job_type, location,
                 application_deadline, status_id, reviewed_by, reviewed_at)
SELECT r.recruiter_id, 'TR Job', 'Test job', 'full_time', 'Delhi',
       CURRENT_DATE + 30, 2, a.user_id, now()
FROM recruiter r, user_account a
WHERE r.full_name = 'TR Recruiter A' AND a.email = 'tr_admin@example.com';
INSERT INTO skill (category_id, skill_name)
SELECT category_id, n FROM skill_category, (VALUES ('TR Skill 1'), ('TR Skill 2')) AS t(n)
WHERE category_name = 'Programming';

\echo ''
\echo 'T12: stored overall score does not match the formula  (expect: refused)'
SAVEPOINT s;
INSERT INTO job_match (student_id, job_id, config_id, mandatory_coverage, preferred_coverage, overall_score)
SELECT s.student_id, j.job_id, c.config_id, 80, 50, 90
FROM student s, job j, match_config c
WHERE s.enrollment_no = 'TR-ENR' AND j.title = 'TR Job' AND c.version_label = 'v1';
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T13: correct overall score 0.70 x 80 + 0.30 x 50 = 71.00  (expect: accepted)'
INSERT INTO job_match (student_id, job_id, config_id, mandatory_coverage, preferred_coverage, overall_score)
SELECT s.student_id, j.job_id, c.config_id, 80, 50, 71.00
FROM student s, job j, match_config c
WHERE s.enrollment_no = 'TR-ENR' AND j.title = 'TR Job' AND c.version_label = 'v1';

\echo ''
\echo 'T14a: UPDATE a stored match result  (expect: refused, insert-only)'
SAVEPOINT s;
UPDATE job_match SET overall_score = 72.00;
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T14b: DELETE a stored match result  (expect: refused, insert-only)'
SAVEPOINT s;
DELETE FROM job_match;
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T15: skill marked matched but levels are below the required level 3  (expect: refused)'
SAVEPOINT s;
INSERT INTO job_match_detail (match_id, skill_id, was_mandatory, required_level_id,
                              student_level_id, evidence_level_id, is_matched)
SELECT m.match_id, sk.skill_id, TRUE, 3, 1, NULL, TRUE
FROM job_match m, skill sk WHERE sk.skill_name = 'TR Skill 1';
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T16: valid match details, one matched and one missing  (expect: 2 x INSERT 0 1)'
INSERT INTO job_match_detail (match_id, skill_id, was_mandatory, required_level_id,
                              student_level_id, evidence_level_id, is_matched)
SELECT m.match_id, sk.skill_id, TRUE, 2, 3, NULL, TRUE
FROM job_match m, skill sk WHERE sk.skill_name = 'TR Skill 1';
INSERT INTO job_match_detail (match_id, skill_id, was_mandatory, required_level_id,
                              student_level_id, evidence_level_id, is_matched)
SELECT m.match_id, sk.skill_id, FALSE, 2, NULL, NULL, FALSE
FROM job_match m, skill sk WHERE sk.skill_name = 'TR Skill 2';

\echo ''
\echo 'T17: new application gets its first history row  (expect: INSERT 0 1, then stage applied)'
INSERT INTO application (student_id, job_id, match_id)
SELECT m.student_id, m.job_id, m.match_id FROM job_match m;
SELECT stage_name FROM v_application_current_stage;

\echo ''
\echo 'T18a: the owner student sets stage 3 (interview)  (expect: refused)'
SAVEPOINT s;
INSERT INTO application_history (application_id, stage_id, changed_by, remarks)
SELECT (SELECT application_id FROM application), 3, user_id, 'T18a'
FROM user_account WHERE email = 'tr_student@example.com';
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T18b: another student withdraws this application  (expect: refused)'
SAVEPOINT s;
INSERT INTO application_history (application_id, stage_id, changed_by, remarks)
SELECT (SELECT application_id FROM application), 6, user_id, 'T18b'
FROM user_account WHERE email = 'tr_student2@example.com';
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T19: a recruiter of another company shortlists  (expect: refused)'
SAVEPOINT s;
INSERT INTO application_history (application_id, stage_id, changed_by, remarks)
SELECT (SELECT application_id FROM application), 2, user_id, 'T19'
FROM user_account WHERE email = 'tr_r2@example.com';
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T20: the recruiter of the same company shortlists  (expect: INSERT 0 1, then stage shortlisted)'
INSERT INTO application_history (application_id, stage_id, changed_by, remarks)
SELECT (SELECT application_id FROM application), 2, user_id, 'T20'
FROM user_account WHERE email = 'tr_r1@example.com';
SELECT stage_name FROM v_application_current_stage;

\echo ''
\echo 'T21: placement while the stage is shortlisted  (expect: refused)'
SAVEPOINT s;
INSERT INTO placement (application_id, offer_status, package_lpa, offer_date)
SELECT application_id, 'offered', 6.50, CURRENT_DATE FROM application;
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T22: offer first, then placement  (expect: 2 x INSERT 0 1)'
INSERT INTO application_history (application_id, stage_id, changed_by, remarks)
SELECT (SELECT application_id FROM application), 4, user_id, 'T22'
FROM user_account WHERE email = 'tr_r1@example.com';
INSERT INTO placement (application_id, offer_status, package_lpa, offer_date)
SELECT application_id, 'offered', 6.50, CURRENT_DATE FROM application;

\echo ''
\echo 'T23a: UPDATE application history  (expect: refused, insert-only)'
SAVEPOINT s;
UPDATE application_history SET remarks = 'changed';
ROLLBACK TO SAVEPOINT s;

\echo ''
\echo 'T23b: DELETE application history  (expect: refused, insert-only)'
SAVEPOINT s;
DELETE FROM application_history;
ROLLBACK TO SAVEPOINT s;

ROLLBACK;

\echo ''
\echo 'Done. Refused tests: T12, T14a, T14b, T15, T18a, T18b, T19, T21, T23a, T23b. Accepted: T13, T16, T17, T20, T22.'