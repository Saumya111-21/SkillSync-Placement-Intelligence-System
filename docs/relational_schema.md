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