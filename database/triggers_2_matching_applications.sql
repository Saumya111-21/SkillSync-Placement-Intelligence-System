-- SkillSync triggers, part 2: matching history, applications and placements
-- Source: docs/relational_schema.md (Group 4 rules for Phase 4 triggers)

BEGIN;

-- 1. Insert-only tables: history is never rewritten.
CREATE OR REPLACE FUNCTION trg_block_change() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'rows in % are insert-only: % is not allowed',
        TG_TABLE_NAME, TG_OP
        USING ERRCODE = 'check_violation';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_job_match_insert_only
    BEFORE UPDATE OR DELETE ON job_match
    FOR EACH ROW EXECUTE FUNCTION trg_block_change();

CREATE TRIGGER trg_job_match_detail_insert_only
    BEFORE UPDATE OR DELETE ON job_match_detail
    FOR EACH ROW EXECUTE FUNCTION trg_block_change();

CREATE TRIGGER trg_application_history_insert_only
    BEFORE UPDATE OR DELETE ON application_history
    FOR EACH ROW EXECUTE FUNCTION trg_block_change();

-- 2. The stored overall score must equal the documented formula.
CREATE OR REPLACE FUNCTION trg_check_match_score() RETURNS trigger AS $$
DECLARE
    v_weight   NUMERIC;
    v_expected NUMERIC;
BEGIN
    SELECT mandatory_weight INTO v_weight
    FROM match_config WHERE config_id = NEW.config_id;

    v_expected := ROUND(v_weight * NEW.mandatory_coverage
                      + (1 - v_weight) * NEW.preferred_coverage, 2);

    IF NEW.overall_score <> v_expected THEN
        RAISE EXCEPTION 'overall_score % does not match the calculation % for config %',
            NEW.overall_score, v_expected, NEW.config_id
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_job_match_score
    BEFORE INSERT ON job_match
    FOR EACH ROW EXECUTE FUNCTION trg_check_match_score();

-- 3. A skill can be marked matched only if a stored level reaches the
-- required level. The full matching rule is defined in Phase 7.
CREATE OR REPLACE FUNCTION trg_check_match_detail() RETURNS trigger AS $$
BEGIN
    IF NEW.is_matched AND NOT (
           COALESCE(NEW.student_level_id,  0) >= NEW.required_level_id
        OR COALESCE(NEW.evidence_level_id, 0) >= NEW.required_level_id
    ) THEN
        RAISE EXCEPTION 'skill % is marked matched but no stored level reaches the required level',
            NEW.skill_id
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_job_match_detail_check
    BEFORE INSERT ON job_match_detail
    FOR EACH ROW EXECUTE FUNCTION trg_check_match_detail();

-- 4. Every new application gets its first history row, stage applied.
CREATE OR REPLACE FUNCTION trg_application_first_history() RETURNS trigger AS $$
BEGIN
    INSERT INTO application_history (application_id, stage_id, changed_by, remarks)
    SELECT NEW.application_id, 1, s.user_id, 'Application submitted'
    FROM student s
    WHERE s.student_id = NEW.student_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_first_history
    AFTER INSERT ON application
    FOR EACH ROW EXECUTE FUNCTION trg_application_first_history();

-- 5. Who may write which stage.
CREATE OR REPLACE FUNCTION trg_check_history_change() RETURNS trigger AS $$
DECLARE
    v_role        TEXT;
    v_owner       INTEGER;
    v_rec_company INTEGER;
    v_app_company INTEGER;
BEGIN
    SELECT role INTO v_role FROM user_account WHERE user_id = NEW.changed_by;

    IF v_role = 'student' THEN
        SELECT s.user_id INTO v_owner
        FROM application a
        JOIN student s ON s.student_id = a.student_id
        WHERE a.application_id = NEW.application_id;

        IF v_owner IS DISTINCT FROM NEW.changed_by THEN
            RAISE EXCEPTION 'a student can change only their own application'
                USING ERRCODE = 'check_violation';
        END IF;
        IF NEW.stage_id NOT IN (1, 6) THEN
            RAISE EXCEPTION 'a student can only apply (stage 1) or withdraw (stage 6), not set stage %',
                NEW.stage_id
                USING ERRCODE = 'check_violation';
        END IF;

    ELSIF v_role IN ('recruiter', 'admin') THEN
        IF NEW.stage_id NOT IN (2, 3, 4, 5) THEN
            RAISE EXCEPTION 'a recruiter or admin can set stages 2 to 5 only, not stage %',
                NEW.stage_id
                USING ERRCODE = 'check_violation';
        END IF;

        IF v_role = 'recruiter' THEN
            SELECT r.company_id INTO v_rec_company
            FROM recruiter r WHERE r.user_id = NEW.changed_by;

            SELECT r2.company_id INTO v_app_company
            FROM application a
            JOIN job j        ON j.job_id = a.job_id
            JOIN recruiter r2 ON r2.recruiter_id = j.recruiter_id
            WHERE a.application_id = NEW.application_id;

            IF v_rec_company IS DISTINCT FROM v_app_company THEN
                RAISE EXCEPTION 'a recruiter can change only applications for jobs of their own company'
                    USING ERRCODE = 'check_violation';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_history_check
    BEFORE INSERT ON application_history
    FOR EACH ROW EXECUTE FUNCTION trg_check_history_change();

-- 6. A placement needs the application to be at stage offered (4).
CREATE OR REPLACE FUNCTION trg_check_placement() RETURNS trigger AS $$
DECLARE
    v_stage SMALLINT;
BEGIN
    SELECT stage_id INTO v_stage
    FROM v_application_current_stage
    WHERE application_id = NEW.application_id;

    IF v_stage IS DISTINCT FROM 4 THEN
        RAISE EXCEPTION 'a placement needs the application to be at stage offered, current stage is %',
            COALESCE(v_stage::TEXT, 'none')
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_placement_check
    BEFORE INSERT ON placement
    FOR EACH ROW EXECUTE FUNCTION trg_check_placement();

COMMIT;
