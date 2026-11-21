-- SkillSync views: derived data that is never stored as a table
-- Source: docs/relational_schema.md (summary of derived data)

BEGIN;

-- Overall CGPA. Credits are not stored, so this is the simple average of
-- the SGPAs, not a credit-weighted CGPA.
CREATE VIEW v_student_cgpa AS
SELECT student_id,
       ROUND(AVG(sgpa), 2) AS cgpa,
       COUNT(*)            AS semesters_recorded
FROM academic_record
GROUP BY student_id;

-- The assessed level is found from the score ranges in proficiency_level.
CREATE VIEW v_skill_assessment_level AS
SELECT a.assessment_id,
       a.student_id,
       a.skill_id,
       a.score_percent,
       a.taken_at,
       p.level_id   AS assessed_level_id,
       p.level_name AS assessed_level_name
FROM skill_assessment a
JOIN proficiency_level p
  ON a.score_percent BETWEEN p.min_score AND p.max_score;

-- Evidence per student and skill. Projects and certifications are shown as
-- counts: they support a skill but do not prove a level. Only an assessment
-- gives a level.
CREATE VIEW v_student_skill_evidence AS
WITH pairs AS (
    SELECT student_id, skill_id FROM student_skill
    UNION
    SELECT sp.student_id, ps.skill_id
    FROM student_project sp
    JOIN project_skill ps ON ps.project_id = sp.project_id
    UNION
    SELECT sc.student_id, cs.skill_id
    FROM student_certification sc
    JOIN certification_skill cs ON cs.certification_id = sc.certification_id
    UNION
    SELECT student_id, skill_id FROM skill_assessment
),
proj AS (
    SELECT sp.student_id, ps.skill_id,
           COUNT(DISTINCT sp.project_id) AS project_count
    FROM student_project sp
    JOIN project_skill ps ON ps.project_id = sp.project_id
    GROUP BY sp.student_id, ps.skill_id
),
cert AS (
    SELECT sc.student_id, cs.skill_id,
           COUNT(DISTINCT sc.certification_id) AS certification_count
    FROM student_certification sc
    JOIN certification_skill cs ON cs.certification_id = sc.certification_id
    GROUP BY sc.student_id, cs.skill_id
),
latest AS (
    SELECT DISTINCT ON (student_id, skill_id)
           student_id, skill_id, assessed_level_id
    FROM v_skill_assessment_level
    ORDER BY student_id, skill_id, taken_at DESC, assessment_id DESC
)
SELECT p.student_id,
       p.skill_id,
       ss.declared_level_id,
       COALESCE(proj.project_count, 0)::INTEGER       AS project_count,
       COALESCE(cert.certification_count, 0)::INTEGER AS certification_count,
       latest.assessed_level_id                       AS latest_assessed_level_id,
       CASE
           WHEN latest.assessed_level_id IS NOT NULL     THEN 'assessed'
           WHEN COALESCE(cert.certification_count, 0) > 0 THEN 'certification'
           WHEN COALESCE(proj.project_count, 0) > 0       THEN 'project'
           ELSE 'declared only'
       END AS strongest_evidence
FROM pairs p
LEFT JOIN student_skill ss ON ss.student_id = p.student_id AND ss.skill_id = p.skill_id
LEFT JOIN proj   ON proj.student_id   = p.student_id AND proj.skill_id   = p.skill_id
LEFT JOIN cert   ON cert.student_id   = p.student_id AND cert.skill_id   = p.skill_id
LEFT JOIN latest ON latest.student_id = p.student_id AND latest.skill_id = p.skill_id;

-- Current stage of an application = its newest history row.
CREATE VIEW v_application_current_stage AS
SELECT DISTINCT ON (h.application_id)
       h.application_id,
       h.stage_id,
       s.stage_name,
       h.changed_at,
       h.changed_by
FROM application_history h
JOIN application_stage s ON s.stage_id = h.stage_id
ORDER BY h.application_id, h.changed_at DESC, h.history_id DESC;

-- Jobs a student may see: job approved and open, company approved,
-- deadline not yet passed.
CREATE VIEW v_open_jobs AS
SELECT j.job_id,
       j.title,
       j.job_type,
       j.location,
       j.min_cgpa,
       j.application_deadline,
       j.posted_at,
       c.company_id,
       c.company_name
FROM job j
JOIN recruiter r ON r.recruiter_id = j.recruiter_id
JOIN company   c ON c.company_id   = r.company_id
WHERE j.is_open
  AND j.status_id = 2
  AND c.status_id = 2
  AND j.application_deadline >= CURRENT_DATE;

-- Newest match result for each student and job.
CREATE VIEW v_latest_job_match AS
SELECT DISTINCT ON (student_id, job_id)
       match_id,
       student_id,
       job_id,
       config_id,
       mandatory_coverage,
       preferred_coverage,
       overall_score,
       calculated_at
FROM job_match
ORDER BY student_id, job_id, calculated_at DESC, match_id DESC;

COMMIT;