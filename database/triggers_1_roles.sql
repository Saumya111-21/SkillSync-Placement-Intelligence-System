-- SkillSync triggers, part 1: account role rules
-- Source: docs/relational_schema.md (Group 1 and Group 3 rules for Phase 4)

BEGIN;

-- Generic check. The trigger passes two arguments:
--   TG_ARGV[0] = the column that holds a user id
--   TG_ARGV[1] = the role that account must have
CREATE OR REPLACE FUNCTION trg_require_role() RETURNS trigger AS $$
DECLARE
    v_user_id INTEGER;
    v_role    TEXT;
BEGIN
    EXECUTE format('SELECT ($1).%I', TG_ARGV[0]) INTO v_user_id USING NEW;

    -- An empty value (for example reviewed_by before review) is allowed here.
    IF v_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT role INTO v_role FROM user_account WHERE user_id = v_user_id;

    IF v_role IS DISTINCT FROM TG_ARGV[1] THEN
        RAISE EXCEPTION '% in table % must belong to an account with role %, found %',
            TG_ARGV[0], TG_TABLE_NAME, TG_ARGV[1], COALESCE(v_role, 'none')
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_student_user_role
    BEFORE INSERT OR UPDATE OF user_id ON student
    FOR EACH ROW EXECUTE FUNCTION trg_require_role('user_id', 'student');

CREATE TRIGGER trg_recruiter_user_role
    BEFORE INSERT OR UPDATE OF user_id ON recruiter
    FOR EACH ROW EXECUTE FUNCTION trg_require_role('user_id', 'recruiter');

CREATE TRIGGER trg_company_reviewer_role
    BEFORE INSERT OR UPDATE OF reviewed_by ON company
    FOR EACH ROW EXECUTE FUNCTION trg_require_role('reviewed_by', 'admin');

CREATE TRIGGER trg_job_reviewer_role
    BEFORE INSERT OR UPDATE OF reviewed_by ON job
    FOR EACH ROW EXECUTE FUNCTION trg_require_role('reviewed_by', 'admin');

-- An account's role cannot change while other tables rely on it.
CREATE OR REPLACE FUNCTION trg_block_role_change() RETURNS trigger AS $$
BEGIN
    IF NEW.role <> OLD.role AND (
           EXISTS (SELECT 1 FROM student   WHERE user_id     = OLD.user_id)
        OR EXISTS (SELECT 1 FROM recruiter WHERE user_id     = OLD.user_id)
        OR EXISTS (SELECT 1 FROM company   WHERE reviewed_by = OLD.user_id)
        OR EXISTS (SELECT 1 FROM job       WHERE reviewed_by = OLD.user_id)
    ) THEN
        RAISE EXCEPTION 'role of user % cannot change: the account is already in use as % ',
            OLD.user_id, OLD.role
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_account_role_change
    BEFORE UPDATE OF role ON user_account
    FOR EACH ROW EXECUTE FUNCTION trg_block_role_change();

COMMIT;