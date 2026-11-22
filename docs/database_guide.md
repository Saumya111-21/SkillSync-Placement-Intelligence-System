# Database Guide

How to build and check the SkillSync PostgreSQL database from nothing.
Tested with PostgreSQL 18.7 on Windows. All sample data is synthetic (invented).

## 1. What the database folder contains

| File | Purpose |
|---|---|
| 01 to 04 | The 28 tables, in four groups, in the order they must be created |
| 05_seed_lookup_data.sql | Fixed rows the rules depend on: 4 proficiency levels, 3 review statuses, 6 application stages, 8 skill categories, 1 matching config (v1) |
| 06 to 11 | Synthetic sample data: reference data, companies, jobs, students, declared skills, evidence |
| views.sql | 6 views for derived data (CGPA, assessed level, evidence, current stage, open jobs, latest match) |
| triggers_1_roles.sql, triggers_2_matching_applications.sql | 13 triggers for rules a column constraint cannot check |
| build_database.sql | Runs everything above in the right order |
| indexes.sql | Indexes. Deliberately NOT part of the build: run it after the Phase 10 baseline timings |

## 2. Requirements

- PostgreSQL 18 (the schema uses an exclusion constraint on ranges, identity columns and plpgsql triggers).
- The psql tool on the PATH.

## 3. Create the database and user

Run as the PostgreSQL superuser (postgres). Choose your own password when psql asks.

    psql -U postgres -h localhost
    CREATE ROLE skillsync_app LOGIN;
    \password skillsync_app
    CREATE DATABASE skillsync OWNER skillsync_app;
    \q

Never write the password in a file that is committed to Git.

## 4. Build

From the project folder, against an EMPTY database:

    psql -U skillsync_app -h localhost -d skillsync -v ON_ERROR_STOP=1 -f database\build_database.sql

Expected: five section labels, a COMMIT for every file, no ERROR, and the last line "--- Build finished ---".
ON_ERROR_STOP makes psql stop at the first error. Each file runs inside a transaction, so a failing file leaves nothing half-created.

## 5. Verify

Count the tables (expected 28):

    psql -U skillsync_app -h localhost -d skillsync -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"

Expected row counts after the build: user_account 18, student 10, academic_record 54, skill 30, student_skill 67, job 12, job_skill 61, company 6, recruiter 7, student_project 12, project_skill 31, skill_assessment 14, and 0 in job_match, job_match_detail, application, application_history, interview and placement.

Rebuild check done on 22-11-2026: the build script was run against a new empty database. The row counts of all 28 tables were identical to the original database (compared with the Windows fc command).
Note: id numbers can differ between the two, because the original database used some identity numbers in tests that were rolled back.

## 6. Run the tests

Every test runs inside a transaction that is rolled back, so no test data is kept. Identity numbers are still used up, which is normal.

    psql -U skillsync_app -h localhost -d skillsync -f tests\test_constraints_1.sql
    psql -U skillsync_app -h localhost -d skillsync -f tests\test_triggers_1.sql
    psql -U skillsync_app -h localhost -d skillsync -f tests\test_triggers_2.sql
    psql -U skillsync_app -h localhost -d skillsync -f tests\test_views_1.sql

Real results of the runs are recorded in docs/test_results.md.

## 7. Notes

- The sample accounts use the text SAMPLE-PLACEHOLDER-NOT-A-HASH as password_hash. Nobody can log in with them. Real password hashes are created by the application in a later phase.
- The deadlines of the sample jobs are relative to the day the sample data is loaded, so the list shown by v_open_jobs changes as those dates pass.
- The preferred weight of a matching config is not stored. It is calculated as 1 - mandatory_weight.
- job_match and job_match_detail are stored result snapshots: documented as 2NF by design in docs/normalization.md.
