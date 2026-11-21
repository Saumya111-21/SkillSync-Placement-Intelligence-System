-- SkillSync schema, part 2: skills, projects and certifications
-- Source: docs/relational_schema.md (Group 2)

BEGIN;

CREATE TABLE skill_category (
    category_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE skill (
    skill_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id  INTEGER      NOT NULL
                 REFERENCES skill_category (category_id) ON DELETE RESTRICT,
    skill_name   VARCHAR(100) NOT NULL UNIQUE
);

-- Fixed lookup table: ids 1 to 4 are chosen by us, not auto-numbered.
-- The EXCLUDE constraint makes PostgreSQL reject overlapping score ranges.
CREATE TABLE proficiency_level (
    level_id    SMALLINT    PRIMARY KEY CHECK (level_id BETWEEN 1 AND 4),
    level_name  VARCHAR(20) NOT NULL UNIQUE,
    min_score   SMALLINT    NOT NULL UNIQUE CHECK (min_score BETWEEN 0 AND 100),
    max_score   SMALLINT    NOT NULL UNIQUE CHECK (max_score BETWEEN 0 AND 100),
    CHECK (min_score <= max_score),
    EXCLUDE USING gist (int4range(min_score, max_score, '[]') WITH &&)
);

CREATE TABLE student_skill (
    student_id         INTEGER     NOT NULL
                       REFERENCES student (student_id) ON DELETE CASCADE,
    skill_id           INTEGER     NOT NULL
                       REFERENCES skill (skill_id) ON DELETE RESTRICT,
    declared_level_id  SMALLINT    NOT NULL
                       REFERENCES proficiency_level (level_id) ON DELETE RESTRICT,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (student_id, skill_id)
);

CREATE TABLE student_project (
    project_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id   INTEGER      NOT NULL
                 REFERENCES student (student_id) ON DELETE CASCADE,
    title        VARCHAR(200) NOT NULL,
    description  TEXT         NOT NULL,
    start_date   DATE         NOT NULL,
    end_date     DATE,
    project_url  VARCHAR(500),
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE project_skill (
    project_id  INTEGER NOT NULL
                REFERENCES student_project (project_id) ON DELETE CASCADE,
    skill_id    INTEGER NOT NULL
                REFERENCES skill (skill_id) ON DELETE RESTRICT,
    PRIMARY KEY (project_id, skill_id)
);

CREATE TABLE certification (
    certification_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    certification_name  VARCHAR(200) NOT NULL,
    issuing_body        VARCHAR(100) NOT NULL,
    UNIQUE (certification_name, issuing_body)
);

CREATE TABLE certification_skill (
    certification_id  INTEGER NOT NULL
                      REFERENCES certification (certification_id) ON DELETE CASCADE,
    skill_id          INTEGER NOT NULL
                      REFERENCES skill (skill_id) ON DELETE RESTRICT,
    PRIMARY KEY (certification_id, skill_id)
);

CREATE TABLE student_certification (
    student_id        INTEGER NOT NULL
                      REFERENCES student (student_id) ON DELETE CASCADE,
    certification_id  INTEGER NOT NULL
                      REFERENCES certification (certification_id) ON DELETE RESTRICT,
    issue_date        DATE    NOT NULL CHECK (issue_date <= CURRENT_DATE),
    credential_id     VARCHAR(100),
    credential_url    VARCHAR(500),
    PRIMARY KEY (student_id, certification_id)
);

-- The assessed level is not stored. It is derived from score_percent
-- by a view that joins to proficiency_level (min_score, max_score).
CREATE TABLE skill_assessment (
    assessment_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id     INTEGER     NOT NULL
                   REFERENCES student (student_id) ON DELETE CASCADE,
    skill_id       INTEGER     NOT NULL
                   REFERENCES skill (skill_id) ON DELETE RESTRICT,
    score_percent  SMALLINT    NOT NULL CHECK (score_percent BETWEEN 0 AND 100),
    taken_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMIT;