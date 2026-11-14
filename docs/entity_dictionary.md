# Entity Dictionary

PK = primary key, FK = foreign key, UQ = must be unique.

## Group 1: Accounts and Academic Entities

### USER_ACCOUNT
Login account for every person using the system. Passwords are stored only as hashes.

| Attribute | Key | Notes |
|---|---|---|
| user_id | PK | Unique number for each account |
| email | UQ | Used to log in |
| password_hash | | Never the plain password |
| role | | student, recruiter or admin |
| is_active | | Lets an admin disable an account |
| created_at | | When the account was made |

### DEPARTMENT
| Attribute | Key | Notes |
|---|---|---|
| department_id | PK | |
| department_name | UQ | For example Computer Science |

### COURSE
One department has many courses.

| Attribute | Key | Notes |
|---|---|---|
| course_id | PK | |
| department_id | FK | Points to DEPARTMENT |
| course_name | | For example B.Tech CSE |
| duration_years | | |

Rule: the same course name cannot appear twice in one department.

### STUDENT
One student belongs to one course. The department is found through COURSE, so it is not stored here.

| Attribute | Key | Notes |
|---|---|---|
| student_id | PK | |
| user_id | FK, UQ | Points to USER_ACCOUNT, one account per student |
| course_id | FK | Points to COURSE |
| enrollment_no | UQ | University enrollment number |
| full_name | | |
| phone | | Optional |
| admission_year | | Current year is calculated from this |

Gender, date of birth and similar attributes are deliberately not stored, so they can never affect matching.

### ACADEMIC_RECORD
One row per semester per student. Overall CGPA is calculated from these rows, never stored.

| Attribute | Key | Notes |
|---|---|---|
| record_id | PK | |
| student_id | FK | Points to STUDENT |
| semester_no | | 1 to 8 |
| sgpa | | Semester grade, 0 to 10 |

Rule: a student cannot have two records for the same semester.