-- SkillSync schema, part 4: matching, applications, interviews, placements
-- Source: docs/relational_schema.md (Group 4)

BEGIN;

-- The preferred weight is not stored. It is 1 - mandatory_weight.
CREATE TABLE match_config (
    config_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version_label     VARCHAR(20)  NOT NULL UNIQUE,
    mandatory_weight  NUMERIC(3,2) NOT NULL
                      CHECK (mandatory_weight BETWEEN 0 AND 1),
    description       TEXT         NOT NULL,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- One row per calculation. Stored scores are a result snapshot (2NF by design).
CREATE TABLE job_match (
    match_id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id          INTEGER      NOT NULL
                        REFERENCES student (student_id) ON DELETE RESTRICT,
    job_id              INTEGER      NOT NULL
                        REFERENCES job (job_id) ON DELETE RESTRICT,
    config_id           INTEGER      NOT NULL
                        REFERENCES match_config (config_id) ON DELETE RESTRICT,
    mandatory_coverage  NUMERIC(5,2) NOT NULL
                        CHECK (mandatory_coverage BETWEEN 0 AND 100),
    preferred_coverage  NUMERIC(5,2) NOT NULL
                        CHECK (preferred_coverage BETWEEN 0 AND 100),
    overall_score       NUMERIC(5,2) NOT NULL
                        CHECK (overall_score BETWEEN 0 AND 100),
    calculated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    -- needed as the target of the composite foreign key in application
    UNIQUE (match_id, student_id, job_id)
);

-- Snapshot of one required skill inside one calculation.
CREATE TABLE job_match_detail (
    match_id           INTEGER  NOT NULL
                       REFERENCES job_match (match_id) ON DELETE RESTRICT,
    skill_id           INTEGER  NOT NULL
                       REFERENCES skill (skill_id) ON DELETE RESTRICT,
    was_mandatory      BOOLEAN  NOT NULL,
    required_level_id  SMALLINT NOT NULL
                       REFERENCES proficiency_level (level_id) ON DELETE RESTRICT,
    student_level_id   SMALLINT
                       REFERENCES proficiency_level (level_id) ON DELETE RESTRICT,
    evidence_level_id  SMALLINT
                       REFERENCES proficiency_level (level_id) ON DELETE RESTRICT,
    is_matched         BOOLEAN  NOT NULL,
    PRIMARY KEY (match_id, skill_id)
);

-- Fixed lookup table: 1 applied, 2 shortlisted, 3 interview,
-- 4 offered, 5 rejected, 6 withdrawn (inserted later).
CREATE TABLE application_stage (
    stage_id     SMALLINT    PRIMARY KEY CHECK (stage_id BETWEEN 1 AND 6),
    stage_name   VARCHAR(20) NOT NULL UNIQUE,
    stage_order  SMALLINT    NOT NULL
);

CREATE TABLE application (
    application_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id      INTEGER     NOT NULL
                    REFERENCES student (student_id) ON DELETE RESTRICT,
    job_id          INTEGER     NOT NULL
                    REFERENCES job (job_id) ON DELETE RESTRICT,
    match_id        INTEGER     UNIQUE,
    applied_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- a student applies to a job only once
    UNIQUE (student_id, job_id),
    -- the attached match must belong to the same student and the same job;
    -- when match_id is empty, this check is skipped
    FOREIGN KEY (match_id, student_id, job_id)
        REFERENCES job_match (match_id, student_id, job_id) ON DELETE RESTRICT
);

CREATE TABLE application_history (
    history_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id  INTEGER     NOT NULL
                    REFERENCES application (application_id) ON DELETE RESTRICT,
    stage_id        SMALLINT    NOT NULL
                    REFERENCES application_stage (stage_id) ON DELETE RESTRICT,
    changed_by      INTEGER     NOT NULL
                    REFERENCES user_account (user_id) ON DELETE RESTRICT,
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    remarks         TEXT
);

CREATE TABLE interview (
    interview_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id  INTEGER     NOT NULL
                    REFERENCES application (application_id) ON DELETE RESTRICT,
    round_no        SMALLINT    NOT NULL CHECK (round_no >= 1),
    scheduled_at    TIMESTAMPTZ NOT NULL,
    mode            VARCHAR(10) NOT NULL
                    CHECK (mode IN ('online', 'in_person')),
    outcome         VARCHAR(10) NOT NULL DEFAULT 'pending'
                    CHECK (outcome IN ('pending', 'passed', 'failed')),
    UNIQUE (application_id, round_no)
);

CREATE TABLE placement (
    placement_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    application_id  INTEGER      NOT NULL UNIQUE
                    REFERENCES application (application_id) ON DELETE RESTRICT,
    offer_status    VARCHAR(10)  NOT NULL
                    CHECK (offer_status IN ('offered', 'accepted', 'declined', 'joined')),
    package_lpa     NUMERIC(6,2) NOT NULL CHECK (package_lpa > 0),
    offer_date      DATE         NOT NULL,
    joining_date    DATE,
    CHECK (joining_date IS NULL OR joining_date >= offer_date)
);

COMMIT;