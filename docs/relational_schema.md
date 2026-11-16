# Final Relational Schema

This is the logical schema after normalization. Tables are grouped as in the entity dictionary. Phase 4 turns each table into a CREATE TABLE statement.

## Conventions

- Names: tables in singular UPPER_CASE here. In PostgreSQL we will use lower_case names, for example user_account.
- Keys: every table has an integer primary key (INTEGER GENERATED ALWAYS AS IDENTITY), except the associative tables, which use a composite primary key.
- Delete rules: RESTRICT is the default, so used data cannot be deleted by accident. CASCADE is used only for rows that make no sense without their parent, such as a student's own semester records.
- Types: INTEGER and SMALLINT (whole numbers), VARCHAR(n) (text with a maximum length), TEXT (text of any length), BOOLEAN (true or false), NUMERIC(p,s) (exact decimals), DATE, TIMESTAMPTZ (date and time with time zone).
- Rules that a column constraint cannot check (for example, that a user's role is admin) are listed under each group and are enforced in Phase 4 with triggers.

## Group 1: Accounts and Academics

### Table: USER_ACCOUNT
| Column | Type | Constraints |
|---|---|---|
| user_id | INTEGER IDENTITY | PRIMARY KEY |
| email | VARCHAR(255) | NOT NULL, UNIQUE |
| password_hash | TEXT | NOT NULL |
| role | VARCHAR(10) | NOT NULL, CHECK (role IN ('student', 'recruiter', 'admin')) |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |

### Table: DEPARTMENT
| Column | Type | Constraints |
|---|---|---|
| department_id | INTEGER IDENTITY | PRIMARY KEY |
| department_name | VARCHAR(100) | NOT NULL, UNIQUE |

### Table: COURSE
| Column | Type | Constraints |
|---|---|---|
| course_id | INTEGER IDENTITY | PRIMARY KEY |
| department_id | INTEGER | NOT NULL, FOREIGN KEY to DEPARTMENT(department_id), ON DELETE RESTRICT |
| course_name | VARCHAR(100) | NOT NULL |
| duration_years | SMALLINT | NOT NULL, CHECK (duration_years BETWEEN 1 AND 6) |

Table constraint: UNIQUE (department_id, course_name).

### Table: STUDENT
| Column | Type | Constraints |
|---|---|---|
| student_id | INTEGER IDENTITY | PRIMARY KEY |
| user_id | INTEGER | NOT NULL, UNIQUE, FOREIGN KEY to USER_ACCOUNT(user_id), ON DELETE RESTRICT |
| course_id | INTEGER | NOT NULL, FOREIGN KEY to COURSE(course_id), ON DELETE RESTRICT |
| enrollment_no | VARCHAR(30) | NOT NULL, UNIQUE |
| full_name | VARCHAR(150) | NOT NULL |
| phone | VARCHAR(15) | optional (can be empty) |
| admission_year | SMALLINT | NOT NULL, CHECK (admission_year BETWEEN 2000 AND 2100) |

### Table: ACADEMIC_RECORD
| Column | Type | Constraints |
|---|---|---|
| record_id | INTEGER IDENTITY | PRIMARY KEY |
| student_id | INTEGER | NOT NULL, FOREIGN KEY to STUDENT(student_id), ON DELETE CASCADE |
| semester_no | SMALLINT | NOT NULL, CHECK (semester_no BETWEEN 1 AND 8) |
| sgpa | NUMERIC(4,2) | NOT NULL, CHECK (sgpa BETWEEN 0 AND 10) |

Table constraint: UNIQUE (student_id, semester_no).

### Group 1 rules for Phase 4 triggers
- STUDENT.user_id must refer to an account whose role is student.
- Overall CGPA is not stored. It is calculated from ACADEMIC_RECORD by a view.

## Group 2: Skills, Projects and Certifications

### Table: SKILL_CATEGORY
| Column | Type | Constraints |
|---|---|---|
| category_id | INTEGER IDENTITY | PRIMARY KEY |
| category_name | VARCHAR(50) | NOT NULL, UNIQUE |

### Table: SKILL
| Column | Type | Constraints |
|---|---|---|
| skill_id | INTEGER IDENTITY | PRIMARY KEY |
| category_id | INTEGER | NOT NULL, FOREIGN KEY to SKILL_CATEGORY(category_id), ON DELETE RESTRICT |
| skill_name | VARCHAR(100) | NOT NULL, UNIQUE |

### Table: PROFICIENCY_LEVEL
| Column | Type | Constraints |
|---|---|---|
| level_id | SMALLINT | PRIMARY KEY, CHECK (level_id BETWEEN 1 AND 4). Fixed values, not auto-numbered |
| level_name | VARCHAR(20) | NOT NULL, UNIQUE |
| min_score | SMALLINT | NOT NULL, UNIQUE, CHECK (min_score BETWEEN 0 AND 100) |
| max_score | SMALLINT | NOT NULL, UNIQUE, CHECK (max_score BETWEEN 0 AND 100) |

Table constraints:
- CHECK (min_score <= max_score).
- EXCLUDE USING gist (int4range(min_score, max_score, '[]') WITH &&). PostgreSQL rejects two levels whose score ranges overlap.

Seed data (inserted in Phase 4): 1 Beginner 0-39, 2 Intermediate 40-64, 3 Advanced 65-84, 4 Expert 85-100. The four ranges together cover every whole score from 0 to 100 with no gap.

### Table: STUDENT_SKILL
| Column | Type | Constraints |
|---|---|---|
| student_id | INTEGER | NOT NULL, FOREIGN KEY to STUDENT(student_id), ON DELETE CASCADE |
| skill_id | INTEGER | NOT NULL, FOREIGN KEY to SKILL(skill_id), ON DELETE RESTRICT |
| declared_level_id | SMALLINT | NOT NULL, FOREIGN KEY to PROFICIENCY_LEVEL(level_id), ON DELETE RESTRICT |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |

Table constraint: PRIMARY KEY (student_id, skill_id).

### Table: STUDENT_PROJECT
| Column | Type | Constraints |
|---|---|---|
| project_id | INTEGER IDENTITY | PRIMARY KEY |
| student_id | INTEGER | NOT NULL, FOREIGN KEY to STUDENT(student_id), ON DELETE CASCADE |
| title | VARCHAR(200) | NOT NULL |
| description | TEXT | NOT NULL |
| start_date | DATE | NOT NULL |
| end_date | DATE | optional (can be empty) |
| project_url | VARCHAR(500) | optional (can be empty) |

Table constraint: CHECK (end_date IS NULL OR end_date >= start_date).

### Table: PROJECT_SKILL
| Column | Type | Constraints |
|---|---|---|
| project_id | INTEGER | NOT NULL, FOREIGN KEY to STUDENT_PROJECT(project_id), ON DELETE CASCADE |
| skill_id | INTEGER | NOT NULL, FOREIGN KEY to SKILL(skill_id), ON DELETE RESTRICT |

Table constraint: PRIMARY KEY (project_id, skill_id).

### Table: CERTIFICATION
| Column | Type | Constraints |
|---|---|---|
| certification_id | INTEGER IDENTITY | PRIMARY KEY |
| certification_name | VARCHAR(200) | NOT NULL |
| issuing_body | VARCHAR(100) | NOT NULL |

Table constraint: UNIQUE (certification_name, issuing_body).

### Table: CERTIFICATION_SKILL
| Column | Type | Constraints |
|---|---|---|
| certification_id | INTEGER | NOT NULL, FOREIGN KEY to CERTIFICATION(certification_id), ON DELETE CASCADE |
| skill_id | INTEGER | NOT NULL, FOREIGN KEY to SKILL(skill_id), ON DELETE RESTRICT |

Table constraint: PRIMARY KEY (certification_id, skill_id).

### Table: STUDENT_CERTIFICATION
| Column | Type | Constraints |
|---|---|---|
| student_id | INTEGER | NOT NULL, FOREIGN KEY to STUDENT(student_id), ON DELETE CASCADE |
| certification_id | INTEGER | NOT NULL, FOREIGN KEY to CERTIFICATION(certification_id), ON DELETE RESTRICT |
| issue_date | DATE | NOT NULL, CHECK (issue_date <= CURRENT_DATE) |
| credential_id | VARCHAR(100) | optional (can be empty) |
| credential_url | VARCHAR(500) | optional (can be empty) |

Table constraint: PRIMARY KEY (student_id, certification_id).

### Table: SKILL_ASSESSMENT
| Column | Type | Constraints |
|---|---|---|
| assessment_id | INTEGER IDENTITY | PRIMARY KEY |
| student_id | INTEGER | NOT NULL, FOREIGN KEY to STUDENT(student_id), ON DELETE CASCADE |
| skill_id | INTEGER | NOT NULL, FOREIGN KEY to SKILL(skill_id), ON DELETE RESTRICT |
| score_percent | SMALLINT | NOT NULL, CHECK (score_percent BETWEEN 0 AND 100). A whole number, so every score falls inside exactly one level range |
| taken_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |

The assessed level is not stored. A view finds it by joining score_percent to the min_score and max_score of PROFICIENCY_LEVEL.

### Group 2 rules for Phase 4
- Evidence for a skill (project, certification, assessment) is derived by a view. Nothing is stored twice.
- A project, certification or assessment never proves expertise by itself. The view reports the evidence source, and the matching engine decides how to use it.

## Group 3: Companies, Recruiters and Jobs

### Table: REVIEW_STATUS
| Column | Type | Constraints |
|---|---|---|
| status_id | SMALLINT | PRIMARY KEY, CHECK (status_id BETWEEN 1 AND 3). Fixed values, not auto-numbered |
| status_name | VARCHAR(20) | NOT NULL, UNIQUE |

Seed data (inserted in Phase 4): 1 pending, 2 approved, 3 rejected.

### Table: COMPANY
| Column | Type | Constraints |
|---|---|---|
| company_id | INTEGER IDENTITY | PRIMARY KEY |
| company_name | VARCHAR(150) | NOT NULL, UNIQUE |
| industry | VARCHAR(100) | NOT NULL |
| website | VARCHAR(300) | optional (can be empty) |
| status_id | SMALLINT | NOT NULL, DEFAULT 1, FOREIGN KEY to REVIEW_STATUS(status_id), ON DELETE RESTRICT |
| reviewed_by | INTEGER | optional (can be empty), FOREIGN KEY to USER_ACCOUNT(user_id), ON DELETE RESTRICT |
| reviewed_at | TIMESTAMPTZ | optional (can be empty) |

Table constraint (review consistency): CHECK ((status_id = 1 AND reviewed_by IS NULL AND reviewed_at IS NULL) OR (status_id <> 1 AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)).

### Table: RECRUITER
| Column | Type | Constraints |
|---|---|---|
| recruiter_id | INTEGER IDENTITY | PRIMARY KEY |
| user_id | INTEGER | NOT NULL, UNIQUE, FOREIGN KEY to USER_ACCOUNT(user_id), ON DELETE RESTRICT |
| company_id | INTEGER | NOT NULL, FOREIGN KEY to COMPANY(company_id), ON DELETE RESTRICT |
| full_name | VARCHAR(150) | NOT NULL |
| designation | VARCHAR(100) | NOT NULL |

### Table: JOB
| Column | Type | Constraints |
|---|---|---|
| job_id | INTEGER IDENTITY | PRIMARY KEY |
| recruiter_id | INTEGER | NOT NULL, FOREIGN KEY to RECRUITER(recruiter_id), ON DELETE RESTRICT |
| title | VARCHAR(200) | NOT NULL |
| description | TEXT | NOT NULL |
| job_type | VARCHAR(15) | NOT NULL, CHECK (job_type IN ('full_time', 'internship')) |
| location | VARCHAR(100) | NOT NULL |
| min_cgpa | NUMERIC(4,2) | optional (can be empty), CHECK (min_cgpa BETWEEN 0 AND 10). An eligibility filter only, never part of the skill score |
| application_deadline | DATE | NOT NULL |
| is_open | BOOLEAN | NOT NULL, DEFAULT TRUE |
| status_id | SMALLINT | NOT NULL, DEFAULT 1, FOREIGN KEY to REVIEW_STATUS(status_id), ON DELETE RESTRICT |
| reviewed_by | INTEGER | optional (can be empty), FOREIGN KEY to USER_ACCOUNT(user_id), ON DELETE RESTRICT |
| reviewed_at | TIMESTAMPTZ | optional (can be empty) |
| posted_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |

Table constraint (review consistency): CHECK ((status_id = 1 AND reviewed_by IS NULL AND reviewed_at IS NULL) OR (status_id <> 1 AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)).

### Table: JOB_SKILL
| Column | Type | Constraints |
|---|---|---|
| job_id | INTEGER | NOT NULL, FOREIGN KEY to JOB(job_id), ON DELETE CASCADE |
| skill_id | INTEGER | NOT NULL, FOREIGN KEY to SKILL(skill_id), ON DELETE RESTRICT |
| is_mandatory | BOOLEAN | NOT NULL |
| min_level_id | SMALLINT | NOT NULL, FOREIGN KEY to PROFICIENCY_LEVEL(level_id), ON DELETE RESTRICT |

Table constraint: PRIMARY KEY (job_id, skill_id).

### Group 3 rules for Phase 4 triggers
- COMPANY.reviewed_by and JOB.reviewed_by must refer to an account whose role is admin.
- RECRUITER.user_id must refer to an account whose role is recruiter.
- The company of a job is found through RECRUITER. It is never stored in JOB.
- Students see only jobs that are approved, open and before the deadline. A view provides this list.