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

## Trigger tests (set 1: account role rules)

Run on 21-11-2026 with tests/test_triggers_1.sql. Each test sets up its own data inside BEGIN and ROLLBACK, so nothing was kept.

| Test ID | Feature | Input | Expected result | Actual result | Status |
|---|---|---|---|---|---|
| T6 | Student account must have role student | Insert a student row linked to an account with role recruiter | Refused by trigger | ERROR: user_id in table student must belong to an account with role student, found recruiter | Passed |
| T7 | Recruiter account must have role recruiter | Insert a recruiter row linked to an account with role student | Refused by trigger | ERROR: user_id in table recruiter must belong to an account with role recruiter, found student | Passed |
| T8 | Company reviewer must be an admin | Approve a company with reviewed_by set to a student account | Refused by trigger | ERROR: reviewed_by in table company must belong to an account with role admin, found student | Passed |
| T9 | Job reviewer must be an admin | Approve a job with reviewed_by set to a recruiter account | Refused by trigger | ERROR: reviewed_by in table job must belong to an account with role admin, found recruiter | Passed |
| T10 | Role of an account in use cannot change | Change the role of an account used as a student to admin | Refused by trigger | ERROR: role of user 8 cannot change: the account is already in use as student | Passed |
| T11 | Valid data is not blocked | Insert an admin, a student and a recruiter account, a department, a course, a student, a company approved by the admin, and a recruiter | All 8 statements accepted | 8 times INSERT 0 1, no error | Passed |

Notes:
- The identity numbers (for example user 8 in T10) are not rolled back, so ids have gaps after rolled-back tests. This is expected PostgreSQL behaviour.
- These tests cover the five role triggers only. The insert-only and score-check triggers are not written yet, so they are not tested and not listed as passed.
- The views are created but have not been tested with data yet.

## Trigger tests (set 2: matching history, applications, placements)

Run on 21-11-2026 with tests/test_triggers_2.sql. The setup data and the accepted steps stayed inside one transaction so later tests could use them. Refused tests used a SAVEPOINT. The final ROLLBACK removed all test data.

| Test ID | Feature | Input | Expected result | Actual result | Status |
|---|---|---|---|---|---|
| T12 | Stored overall score must match the formula | Insert a match with coverage 80 and 50 and overall_score 90 | Refused by trigger | ERROR: overall_score 90.00 does not match the calculation 71.00 for config 1 | Passed |
| T13 | Correct score is accepted | Insert a match with coverage 80 and 50 and overall_score 71.00 (0.70 x 80 + 0.30 x 50) | Accepted | INSERT 0 1 | Passed |
| T14a | Match results are insert-only | UPDATE overall_score of a stored match | Refused by trigger | ERROR: rows in job_match are insert-only: UPDATE is not allowed | Passed |
| T14b | Match results are insert-only | DELETE a stored match | Refused by trigger | ERROR: rows in job_match are insert-only: DELETE is not allowed | Passed |
| T15 | A matched skill needs a level that reaches the requirement | Insert a match detail with is_matched true, required level 3, student level 1, no evidence | Refused by trigger | ERROR: skill 1 is marked matched but no stored level reaches the required level | Passed |
| T16 | Valid match details are accepted | Insert one matched skill (required 2, student level 3) and one missing skill | Both accepted | INSERT 0 1 twice | Passed |
| T17 | First history row is created automatically | Insert an application with the stored match attached | Accepted, current stage is applied | INSERT 0 1. v_application_current_stage showed applied | Passed |
| T18a | A student may only apply or withdraw | The owner student writes stage 3 (interview) | Refused by trigger | ERROR: a student can only apply (stage 1) or withdraw (stage 6), not set stage 3 | Passed |
| T18b | A student may change only their own application | Another student withdraws this application | Refused by trigger | ERROR: a student can change only their own application | Passed |
| T19 | A recruiter may act only on their own company's jobs | A recruiter of another company shortlists | Refused by trigger | ERROR: a recruiter can change only applications for jobs of their own company | Passed |
| T20 | A recruiter of the same company may shortlist | The recruiter of the job's company writes stage 2 | Accepted, current stage is shortlisted | INSERT 0 1. v_application_current_stage showed shortlisted | Passed |
| T21 | A placement needs the stage offered | Insert a placement while the stage is shortlisted | Refused by trigger | ERROR: a placement needs the application to be at stage offered, current stage is 2 | Passed |
| T22 | Offer, then placement is accepted | Recruiter writes stage 4 (offered), then a placement is inserted | Both accepted | INSERT 0 1 twice | Passed |
| T23a | Application history is insert-only | UPDATE a history row | Refused by trigger | ERROR: rows in application_history are insert-only: UPDATE is not allowed | Passed |
| T23b | Application history is insert-only | DELETE a history row | Refused by trigger | ERROR: rows in application_history are insert-only: DELETE is not allowed | Passed |

Notes:
- These tests also exercised the view v_application_current_stage with real data. The other five views are still untested.
- Not covered by any test yet: the order of stages (for example, a rejected application returning to shortlisted is not blocked), a recruiter writing stage 1 or 6 (covered by the code, not tested), and the case is_matched false with levels that would have met the requirement. The last one belongs to the Phase 7 matching engine.
- Identity numbers are not rolled back, so ids have gaps after rolled-back tests. This is expected PostgreSQL behaviour.

## View tests

Run on 22-11-2026 against the sample data (database/06 to 11). T30 to T32 are in tests/test_views_1.sql and ran inside BEGIN and ROLLBACK, so their test data was not kept. T27 to T29 are queries typed in psql against the sample data. Expected values were worked out by hand from the sample data before the queries were run.

| Test ID | Feature | Input | Expected result | Actual result | Status |
|---|---|---|---|---|---|
| T27 | v_student_cgpa: overall CGPA is the average of the SGPAs | Query the view for all 10 sample students | Aarav 8.17 (6 semesters), Diya 8.93 (6), Sahil 6.70 (4), worked out by hand. The other 7 rows are plausible | Aarav 8.17, Diya 8.93, Sahil 6.70 matched. All 10 rows returned with 6 or 4 semesters. The other 7 values were checked against their grades afterwards | Passed |
| T28 | v_student_skill_evidence: evidence levels and sources | Query 3 students for Python, SQL and Excel (8 rows) | Kabir Excel: declared only. Diya SQL: assessed level 3, using the later attempt (78) not the earlier (55). Aarav Python: assessed level 2, below the declared 3. Diya Python: project evidence with no level | All 8 rows matched the hand-worked table exactly | Passed |
| T29 | v_open_jobs: students see only open approved jobs | Query the view, then list the jobs missing from it | 8 jobs shown. 4 hidden: a job pending review, a closed job, a job with a past deadline, a job of a pending company | Exactly those 8 shown and those 4 hidden | Passed |
| T30 | v_skill_assessment_level: score boundaries | Insert scores 0, 39, 40, 64, 65, 84, 85, 100 and read their levels | 0 and 39 level 1, 40 and 64 level 2, 65 and 84 level 3, 85 and 100 level 4 | All 8 scores mapped as expected | Passed |
| T31 | v_skill_assessment_level: one level per assessment | Compare the number of assessments with the number of rows in the view | Equal counts | 22 and 22 | Passed |
| T32 | v_latest_job_match: newest match per student and job | Insert a July match (71.00) first and an older June match (50.00) second | The view returns one row: 71.00 on 2026-07-01 | raw_rows 2. The view returned 71.00, 2026-07-01 | Passed |

Notes:
- v_application_current_stage was tested with real data in T17 and T20 (trigger tests set 2). With these results all six views have been tested.
- T27 to T29 were run by hand and are not saved as a test file. The three queries are reproducible from the sample data. Saving them as a script is a possible later improvement.
- The date-based part of v_open_jobs depends on the day the sample data was loaded, because deadlines are relative to that day. T29 will give a different list once the sample deadlines pass.