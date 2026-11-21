-- SkillSync indexes
-- NOT run during Phase 4. Run after the "without indexes" timings are
-- recorded in Phase 10, so the experiment compares real before and after.
-- Primary keys and UNIQUE constraints are already indexed by PostgreSQL.

BEGIN;

-- Foreign key columns (PostgreSQL does not index these automatically)
CREATE INDEX idx_course_department       ON course (department_id);
CREATE INDEX idx_student_course          ON student (course_id);
CREATE INDEX idx_skill_category          ON skill (category_id);
CREATE INDEX idx_student_skill_skill     ON student_skill (skill_id);
CREATE INDEX idx_student_project_student ON student_project (student_id);
CREATE INDEX idx_project_skill_skill     ON project_skill (skill_id);
CREATE INDEX idx_cert_skill_skill        ON certification_skill (skill_id);
CREATE INDEX idx_student_cert_cert       ON student_certification (certification_id);
CREATE INDEX idx_assessment_skill        ON skill_assessment (skill_id);
CREATE INDEX idx_recruiter_company       ON recruiter (company_id);
CREATE INDEX idx_job_recruiter           ON job (recruiter_id);
CREATE INDEX idx_job_skill_skill         ON job_skill (skill_id);
CREATE INDEX idx_match_job               ON job_match (job_id);
CREATE INDEX idx_match_detail_skill      ON job_match_detail (skill_id);
CREATE INDEX idx_application_job         ON application (job_id);

-- Indexes built for the queries SkillSync actually runs
-- Latest assessment of a student for a skill
CREATE INDEX idx_assessment_student_skill
    ON skill_assessment (student_id, skill_id, taken_at DESC);
-- Match history of one student for one job, newest first
CREATE INDEX idx_match_student_job
    ON job_match (student_id, job_id, calculated_at DESC);
-- Current stage of an application = its newest history row
CREATE INDEX idx_history_app_time
    ON application_history (application_id, changed_at DESC);
-- Jobs students can see: approved and open, ordered by deadline
CREATE INDEX idx_job_open_approved
    ON job (application_deadline) WHERE is_open AND status_id = 2;

COMMIT;