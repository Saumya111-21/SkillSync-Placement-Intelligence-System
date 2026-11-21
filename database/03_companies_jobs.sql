-- SkillSync schema, part 3: companies, recruiters and jobs
-- Source: docs/relational_schema.md (Group 3)

BEGIN;

-- Fixed lookup table: 1 pending, 2 approved, 3 rejected (inserted later).
CREATE TABLE review_status (
    status_id    SMALLINT    PRIMARY KEY CHECK (status_id BETWEEN 1 AND 3),
    status_name  VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE company (
    company_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_name  VARCHAR(150) NOT NULL UNIQUE,
    industry      VARCHAR(100) NOT NULL,
    website       VARCHAR(300),
    status_id     SMALLINT     NOT NULL DEFAULT 1
                  REFERENCES review_status (status_id) ON DELETE RESTRICT,
    reviewed_by   INTEGER
                  REFERENCES user_account (user_id) ON DELETE RESTRICT,
    reviewed_at   TIMESTAMPTZ,
    -- pending: no reviewer, no date. Reviewed: both present.
    CHECK (
        (status_id = 1  AND reviewed_by IS NULL     AND reviewed_at IS NULL)
        OR
        (status_id <> 1 AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
    )
);

CREATE TABLE recruiter (
    recruiter_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       INTEGER      NOT NULL UNIQUE
                  REFERENCES user_account (user_id) ON DELETE RESTRICT,
    company_id    INTEGER      NOT NULL
                  REFERENCES company (company_id) ON DELETE RESTRICT,
    full_name     VARCHAR(150) NOT NULL,
    designation   VARCHAR(100) NOT NULL
);

CREATE TABLE job (
    job_id                INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recruiter_id          INTEGER      NOT NULL
                          REFERENCES recruiter (recruiter_id) ON DELETE RESTRICT,
    title                 VARCHAR(200) NOT NULL,
    description           TEXT         NOT NULL,
    job_type              VARCHAR(15)  NOT NULL
                          CHECK (job_type IN ('full_time', 'internship')),
    location              VARCHAR(100) NOT NULL,
    min_cgpa              NUMERIC(4,2) CHECK (min_cgpa BETWEEN 0 AND 10),
    application_deadline  DATE         NOT NULL,
    is_open               BOOLEAN      NOT NULL DEFAULT TRUE,
    status_id             SMALLINT     NOT NULL DEFAULT 1
                          REFERENCES review_status (status_id) ON DELETE RESTRICT,
    reviewed_by           INTEGER
                          REFERENCES user_account (user_id) ON DELETE RESTRICT,
    reviewed_at           TIMESTAMPTZ,
    posted_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CHECK (
        (status_id = 1  AND reviewed_by IS NULL     AND reviewed_at IS NULL)
        OR
        (status_id <> 1 AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
    )
);

CREATE TABLE job_skill (
    job_id        INTEGER  NOT NULL
                  REFERENCES job (job_id) ON DELETE CASCADE,
    skill_id      INTEGER  NOT NULL
                  REFERENCES skill (skill_id) ON DELETE RESTRICT,
    is_mandatory  BOOLEAN  NOT NULL,
    min_level_id  SMALLINT NOT NULL
                  REFERENCES proficiency_level (level_id) ON DELETE RESTRICT,
    PRIMARY KEY (job_id, skill_id)
);

COMMIT;