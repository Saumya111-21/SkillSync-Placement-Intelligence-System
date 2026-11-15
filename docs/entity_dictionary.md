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
| min_score | | Lowest score_percent that maps to this level |
| max_score | | Highest score_percent that maps to this level. Ranges must not overlap |

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

| taken_at | | When the attempt happened |

## Group 3: Companies, Recruiters and Jobs

### REVIEW_STATUS
Lookup table used for admin approval of both companies and jobs.

| Attribute | Key | Notes |
|---|---|---|
| status_id | PK | |
| status_name | UQ | pending, approved, rejected |

### COMPANY
Company details are stored once here. Jobs reach the company through RECRUITER.

| Attribute | Key | Notes |
|---|---|---|
| company_id | PK | |
| company_name | UQ | |
| industry | | For example IT Services, Analytics |
| website | | Optional |
| status_id | FK | Points to REVIEW_STATUS |
| reviewed_by | FK | Points to USER_ACCOUNT, must be an admin. Empty until reviewed |
| reviewed_at | | Empty until reviewed |

### RECRUITER
Each recruiter belongs to exactly one company.

| Attribute | Key | Notes |
|---|---|---|
| recruiter_id | PK | |
| user_id | FK, UQ | Points to USER_ACCOUNT, one account per recruiter |
| company_id | FK | Points to COMPANY |
| full_name | | |
| designation | | For example HR Manager |

### JOB
The company is found through RECRUITER, so it is not stored here.

| Attribute | Key | Notes |
|---|---|---|
| job_id | PK | |
| recruiter_id | FK | Points to RECRUITER |
| title | | For example Data Analyst |
| description | | |
| job_type | | full_time or internship |
| location | | |
| min_cgpa | | Optional eligibility filter. It is NOT part of the skill score |
| application_deadline | | |
| is_open | | Lets a recruiter close a job without deleting it |
| status_id | FK | Points to REVIEW_STATUS |
| reviewed_by | FK | Points to USER_ACCOUNT, must be an admin. Empty until reviewed |
| reviewed_at | | Empty until reviewed |
| posted_at | | |

### JOB_SKILL
Resolves the many-to-many link between jobs and skills. It holds the job's current requirements.

| Attribute | Key | Notes |
|---|---|---|
| job_id | PK, FK | Points to JOB |
| skill_id | PK, FK | Points to SKILL |
| is_mandatory | | True for mandatory, false for preferred |
| min_level_id | FK | Points to PROFICIENCY_LEVEL, the minimum level required |

If a recruiter edits these rows later, old match results are not affected. Each match stores its own snapshot (Group 4).

## Group 4: Matching, Applications, Interviews and Placements

### MATCH_CONFIG
Stores the settings used for a score calculation, so any score can be reproduced.

| Attribute | Key | Notes |
|---|---|---|
| config_id | PK | |
| version_label | UQ | For example v1 |
| mandatory_weight | | For example 0.70 |
| preferred_weight | | For example 0.30 |
| description | | How the score is calculated, in plain words |
| created_at | | |

Rule: mandatory_weight + preferred_weight must equal 1.

### JOB_MATCH
One row per calculation. The same student and job can have many rows over time.

| Attribute | Key | Notes |
|---|---|---|
| match_id | PK | |
| student_id | FK | Points to STUDENT |
| job_id | FK | Points to JOB |
| config_id | FK | Points to MATCH_CONFIG |
| mandatory_coverage | | Percentage, 0 to 100 |
| preferred_coverage | | Percentage, 0 to 100 |
| overall_score | | Skill-coverage indicator, 0 to 100. Not a hiring probability |
| calculated_at | | When the calculation ran |

### JOB_MATCH_DETAIL
One row per required skill per calculation. It is a snapshot, so it copies the values used at that moment.

| Attribute | Key | Notes |
|---|---|---|
| match_id | PK, FK | Points to JOB_MATCH |
| skill_id | PK, FK | Points to SKILL |
| was_mandatory | | Copied from JOB_SKILL at calculation time |
| required_level_id | FK | Level required at calculation time |
| student_level_id | FK | Student's declared level then. Empty if the student had no such skill |
| evidence_level_id | FK | Highest level supported by evidence then. Empty if none |
| is_matched | | True if the requirement was met |

Missing skills are the rows where is_matched is false.

### APPLICATION_STAGE
Lookup table for recruitment stages.

| Attribute | Key | Notes |
|---|---|---|
| stage_id | PK | |
| stage_name | UQ | applied, shortlisted, interview, offered, rejected, withdrawn |
| stage_order | | Used for sorting |

### APPLICATION
| Attribute | Key | Notes |
|---|---|---|
| application_id | PK | |
| student_id | FK | Points to STUDENT |
| job_id | FK | Points to JOB |
| match_id | FK | Optional. The score the student had when applying |
| applied_at | | |

Rule: the pair (student_id, job_id) is unique, so a student applies once per job. The current stage is not stored here. It is the latest row in APPLICATION_HISTORY, found through a view.

### APPLICATION_HISTORY
| Attribute | Key | Notes |
|---|---|---|
| history_id | PK | |
| application_id | FK | Points to APPLICATION |
| stage_id | FK | Points to APPLICATION_STAGE |
| changed_by | FK | Points to USER_ACCOUNT |
| changed_at | | |
| remarks | | Optional |

### INTERVIEW
| Attribute | Key | Notes |
|---|---|---|
| interview_id | PK | |
| application_id | FK | Points to APPLICATION |
| round_no | | |
| scheduled_at | | |
| mode | | online or in_person |
| outcome | | pending, passed or failed |

Rule: the pair (application_id, round_no) is unique.

### PLACEMENT
Student, job and company are all found through APPLICATION, so none of them is stored here.

| Attribute | Key | Notes |
|---|---|---|
| placement_id | PK | |
| application_id | FK, UQ | Points to APPLICATION, so one application gives at most one placement |
| offer_status | | offered, accepted, declined or joined |
| package_lpa | | Annual package in lakhs |
| offer_date | | |
| joining_date | | Optional |