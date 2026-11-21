-- SkillSync schema, part 1: accounts and academics
-- Source: docs/relational_schema.md (Group 1)

BEGIN;

CREATE TABLE user_account (
    user_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  TEXT         NOT NULL,
    role           VARCHAR(10)  NOT NULL
                   CHECK (role IN ('student', 'recruiter', 'admin')),
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE department (
    department_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name  VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE course (
    course_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_id   INTEGER      NOT NULL
                    REFERENCES department (department_id) ON DELETE RESTRICT,
    course_name     VARCHAR(100) NOT NULL,
    duration_years  SMALLINT     NOT NULL
                    CHECK (duration_years BETWEEN 1 AND 6),
    UNIQUE (department_id, course_name)
);

CREATE TABLE student (
    student_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         INTEGER      NOT NULL UNIQUE
                    REFERENCES user_account (user_id) ON DELETE RESTRICT,
    course_id       INTEGER      NOT NULL
                    REFERENCES course (course_id) ON DELETE RESTRICT,
    enrollment_no   VARCHAR(30)  NOT NULL UNIQUE,
    full_name       VARCHAR(150) NOT NULL,
    phone           VARCHAR(15),
    admission_year  SMALLINT     NOT NULL
                    CHECK (admission_year BETWEEN 2000 AND 2100)
);

CREATE TABLE academic_record (
    record_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id   INTEGER       NOT NULL
                 REFERENCES student (student_id) ON DELETE CASCADE,
    semester_no  SMALLINT      NOT NULL CHECK (semester_no BETWEEN 1 AND 8),
    sgpa         NUMERIC(4,2)  NOT NULL CHECK (sgpa BETWEEN 0 AND 10),
    UNIQUE (student_id, semester_no)
);

COMMIT;