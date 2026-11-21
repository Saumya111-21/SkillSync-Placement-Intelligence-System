# Test Results

Environment: PostgreSQL 18.7, Windows, database skillsync, run as user skillsync_app.
Date of runs: 21-11-2026.
Status values: Passed = the database behaved as expected in a run that was actually executed. Nothing is marked Passed without a run.

## Constraint tests (set 1)

| Test ID | Feature | Input | Expected result | Actual result | Status |
|---|---|---|---|---|---|
| T1 | Score ranges must not overlap (proficiency_level) | UPDATE max_score of Beginner from 39 to 50, which overlaps Intermediate | Refused by the exclusion constraint | ERROR: conflicting key value violates exclusion constraint "proficiency_level_int4range_excl". The row stayed 1, 0, 39 afterwards | Passed |
| T2 | Role must be student, recruiter or admin (user_account) | Insert a user with role teacher | Refused by a check constraint | ERROR: violates check constraint "user_account_role_check" | Passed |
| T3 | Email must be unique (user_account) | Insert the same email twice | Second insert refused | First insert accepted. Second: ERROR: duplicate key value violates unique constraint "user_account_email_key" | Passed |
| T4 | Foreign keys must point to existing rows (student) | Insert a student with user_id 99999 and course_id 99999, which do not exist | Refused by a foreign key | ERROR: violates foreign key constraint "student_user_id_fkey" | Passed |
| T5 | SGPA must be between 0 and 10 (academic_record) | Insert sgpa 11.50 | Refused by a check constraint | ERROR: violates check constraint "academic_record_sgpa_check" | Passed |

How the tests were run: tests T2 to T5 are in tests/test_constraints_1.sql. Every test runs inside BEGIN and ROLLBACK, so no test data was kept. T1 was run once by hand with the same BEGIN and ROLLBACK pattern, and the row was checked afterwards.

Notes:
- PostgreSQL checks check constraints before foreign keys. T5 uses a student_id that does not exist, and the check constraint fired first. So T5 does test the SGPA rule.
- Identity numbers are not rolled back, so ids may have gaps after rolled-back tests. This is expected PostgreSQL behaviour.
- These tests show that the rules above are enforced on this installation. They do not yet cover the triggers, which are not written yet.