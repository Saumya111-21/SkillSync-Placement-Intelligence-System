-- SkillSync constraint tests, set 1 (accounts and academics)
-- Each test must be REFUSED by the database. Every test runs inside
-- BEGIN ... ROLLBACK, so nothing is kept.

\echo ''
\echo 'T2: role outside the allowed list  (expect: check constraint violation)'
BEGIN;
INSERT INTO user_account (email, password_hash, role)
VALUES ('t2@example.com', 'x', 'teacher');
ROLLBACK;

\echo ''
\echo 'T3: duplicate email  (expect: unique constraint violation on the 2nd insert)'
BEGIN;
INSERT INTO user_account (email, password_hash, role)
VALUES ('t3@example.com', 'x', 'student');
INSERT INTO user_account (email, password_hash, role)
VALUES ('t3@example.com', 'y', 'student');
ROLLBACK;

\echo ''
\echo 'T4: student pointing to a course and account that do not exist  (expect: foreign key violation)'
BEGIN;
INSERT INTO student (user_id, course_id, enrollment_no, full_name, admission_year)
VALUES (99999, 99999, 'T4-ENR', 'Test Student', 2023);
ROLLBACK;

\echo ''
\echo 'T5: SGPA above 10  (expect: check constraint violation)'
BEGIN;
INSERT INTO academic_record (student_id, semester_no, sgpa)
VALUES (99999, 1, 11.50);
ROLLBACK;

\echo ''
\echo 'Done. Every test above should have printed an ERROR line.'