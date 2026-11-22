-- SkillSync view tests, set 1
-- Everything runs inside one transaction that is rolled back at the end,
-- so no test data is kept.

BEGIN;

\echo ''
\echo 'V1: score boundaries map to levels'
\echo '    expect: 0 and 39 -> 1 Beginner, 40 and 64 -> 2 Intermediate,'
\echo '            65 and 84 -> 3 Advanced, 85 and 100 -> 4 Expert'
INSERT INTO skill_assessment (student_id, skill_id, score_percent, taken_at)
SELECT st.student_id, sk.skill_id, v.score, now()
FROM (VALUES (0), (39), (40), (64), (65), (84), (85), (100)) AS v(score),
     student st, skill sk
WHERE st.enrollment_no = 'CS23-001' AND sk.skill_name = 'Jira';

SELECT a.score_percent, a.assessed_level_id, a.assessed_level_name
FROM v_skill_assessment_level a
JOIN skill k ON k.skill_id = a.skill_id
WHERE k.skill_name = 'Jira'
ORDER BY a.score_percent;

\echo ''
\echo 'V1b: every assessment gets exactly one level  (expect: both numbers equal, 22 and 22)'
SELECT (SELECT count(*) FROM skill_assessment)         AS assessments,
       (SELECT count(*) FROM v_skill_assessment_level) AS assessments_in_view;

\echo ''
\echo 'V2: latest match per student and job'
\echo '    A newer match (July, score 71.00) is inserted FIRST, an older one (June, 50.00) SECOND.'
\echo '    expect: raw_rows = 2, and the view returns one row: score 71.00, date 2026-07-01'
INSERT INTO job_match (student_id, job_id, config_id, mandatory_coverage,
                       preferred_coverage, overall_score, calculated_at)
SELECT st.student_id, j.job_id, c.config_id, 80, 50, 71.00,
       TIMESTAMPTZ '2026-07-01 10:00+05:30'
FROM student st, job j, match_config c
WHERE st.enrollment_no = 'CS23-001' AND j.title = 'Data Analyst' AND c.version_label = 'v1';

INSERT INTO job_match (student_id, job_id, config_id, mandatory_coverage,
                       preferred_coverage, overall_score, calculated_at)
SELECT st.student_id, j.job_id, c.config_id, 50, 50, 50.00,
       TIMESTAMPTZ '2026-06-01 10:00+05:30'
FROM student st, job j, match_config c
WHERE st.enrollment_no = 'CS23-001' AND j.title = 'Data Analyst' AND c.version_label = 'v1';

SELECT (SELECT count(*) FROM job_match) AS raw_rows;

SELECT overall_score, calculated_at
FROM v_latest_job_match;

ROLLBACK;

\echo ''
\echo 'Done. Nothing was kept.'