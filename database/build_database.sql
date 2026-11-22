-- SkillSync: rebuild the whole database from nothing
-- Run it against an EMPTY database with:
--   psql -U skillsync_app -h localhost -d <database> -v ON_ERROR_STOP=1 -f database\build_database.sql
-- \ir runs a file located next to this one.
-- indexes.sql is NOT included: it is run after the Phase 10 baseline timings.
-- ALL SAMPLE DATA (files 06 to 11) IS SYNTHETIC.

\echo '--- 1. Tables ---'
\ir 01_accounts_academics.sql
\ir 02_skills_projects_certifications.sql
\ir 03_companies_jobs.sql
\ir 04_matching_applications.sql

\echo '--- 2. Views and triggers ---'
\ir views.sql
\ir triggers_1_roles.sql
\ir triggers_2_matching_applications.sql

\echo '--- 3. Lookup data ---'
\ir 05_seed_lookup_data.sql

\echo '--- 4. Sample data (synthetic) ---'
\ir 06_sample_reference.sql
\ir 07_sample_companies.sql
\ir 08_sample_jobs.sql
\ir 09_sample_students.sql
\ir 10_sample_student_skills.sql
\ir 11_sample_evidence.sql

\echo '--- Build finished ---'