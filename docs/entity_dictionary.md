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

## Group 2: Skills, Projects and Certifications

### SKILL_CATEGORY
Lookup table, so categories are never typed differently by different people.

| Attribute | Key | Notes |
|---|---|---|
| category_id | PK | |
| category_name | UQ | For example Programming, Database, Soft Skill |

### SKILL
The master list of all skills in the system.

| Attribute | Key | Notes |
|---|---|---|
| skill_id | PK | |
| category_id | FK | Points to SKILL_CATEGORY |
| skill_name | UQ | For example Python, Power BI |

### PROFICIENCY_LEVEL
Lookup table for skill levels. Used by student skills and by job requirements.

| Attribute | Key | Notes |
|---|---|---|
| level_id | PK | 1 to 4 |
| level_name | UQ | Beginner, Intermediate, Advanced, Expert |

### STUDENT_SKILL
The level a student declares for a skill. Evidence from projects, certifications and assessments is not stored here. It is derived through a view later.

| Attribute | Key | Notes |
|---|---|---|
| student_id | PK, FK | Points to STUDENT |
| skill_id | PK, FK | Points to SKILL |
| declared_level_id | FK | Points to PROFICIENCY_LEVEL |
| updated_at | | When the student last changed it |

The primary key is the pair (student_id, skill_id), so a student cannot list the same skill twice.

### STUDENT_PROJECT
| Attribute | Key | Notes |
|---|---|---|
| project_id | PK | |
| student_id | FK | Points to STUDENT |
| title | | |
| description | | |
| start_date | | |
| end_date | | Optional |
| project_url | | Optional |

### PROJECT_SKILL
Resolves the many-to-many link between projects and skills.

| Attribute | Key | Notes |
|---|---|---|
| project_id | PK, FK | Points to STUDENT_PROJECT |
| skill_id | PK, FK | Points to SKILL |

### CERTIFICATION
The master list of certifications.

| Attribute | Key | Notes |
|---|---|---|
| certification_id | PK | |
| certification_name | | |
| issuing_body | | For example Coursera, Microsoft |

Rule: the same name from the same issuing body cannot appear twice.

### CERTIFICATION_SKILL
New table. Says which skills a certification covers. Without it, the system cannot tell what a certification supports.

| Attribute | Key | Notes |
|---|---|---|
| certification_id | PK, FK | Points to CERTIFICATION |
| skill_id | PK, FK | Points to SKILL |

### STUDENT_CERTIFICATION
Resolves the many-to-many link between students and certifications.

| Attribute | Key | Notes |
|---|---|---|
| student_id | PK, FK | Points to STUDENT |
| certification_id | PK, FK | Points to CERTIFICATION |
| issue_date | | |
| credential_id | | Optional, for verification |
| credential_url | | Optional |

### SKILL_ASSESSMENT
One row per assessment attempt, so repeated attempts are kept.

| Attribute | Key | Notes |
|---|---|---|
| assessment_id | PK | |
| student_id | FK | Points to STUDENT |
| skill_id | FK | Points to SKILL |
| score_percent | | 0 to 100 |
| assessed_level_id | FK | Points to PROFICIENCY_LEVEL, the level this score maps to |
| taken_at | | When the attempt happened |