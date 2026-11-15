# Relationships and Cardinality

Cardinality: 1:1 = one to one, 1:N = one to many, M:N = many to many.

## Part 1: Accounts, Academics, Skills and Certifications

| ID | Entity A | Entity B | Cardinality | Meaning | Implemented by |
|---|---|---|---|---|---|
| R1 | DEPARTMENT | COURSE | 1:N | A department offers many courses. Each course belongs to one department | COURSE.department_id (FK) |
| R2 | COURSE | STUDENT | 1:N | A course has many students. Each student is in one course | STUDENT.course_id (FK) |
| R3 | USER_ACCOUNT | STUDENT | 1:1 | A student has exactly one login account. An account belongs to at most one student | STUDENT.user_id (FK, unique) |
| R4 | STUDENT | ACADEMIC_RECORD | 1:N | A student has many semester records | ACADEMIC_RECORD.student_id (FK) |
| R5 | STUDENT | STUDENT_PROJECT | 1:N | A student creates many projects | STUDENT_PROJECT.student_id (FK) |
| R6 | SKILL_CATEGORY | SKILL | 1:N | A category groups many skills | SKILL.category_id (FK) |
| R7 | STUDENT | SKILL | M:N | A student has many skills. A skill is held by many students | STUDENT_SKILL (student_id, skill_id) |
| R8 | STUDENT_PROJECT | SKILL | M:N | A project uses many skills. A skill appears in many projects | PROJECT_SKILL (project_id, skill_id) |
| R9 | CERTIFICATION | SKILL | M:N | A certification covers many skills. A skill is covered by many certifications | CERTIFICATION_SKILL (certification_id, skill_id) |
| R10 | STUDENT | CERTIFICATION | M:N | A student earns many certifications. A certification is earned by many students | STUDENT_CERTIFICATION (student_id, certification_id) |
| R11 | STUDENT | SKILL_ASSESSMENT | 1:N | A student takes many assessments | SKILL_ASSESSMENT.student_id (FK) |
| R12 | SKILL | SKILL_ASSESSMENT | 1:N | A skill is assessed many times | SKILL_ASSESSMENT.skill_id (FK) |
| R13 | PROFICIENCY_LEVEL | STUDENT_SKILL | 1:N | One level is used by many declared skills | STUDENT_SKILL.declared_level_id (FK) |
| R14 | (removed) | (removed) | - | Removed in Option A. The assessment level is calculated from score_percent using PROFICIENCY_LEVEL.min_score and max_score | no foreign key |

## Part 2: Companies, Jobs, Matching and Applications

| ID | Entity A | Entity B | Cardinality | Meaning | Implemented by |
|---|---|---|---|---|---|
| R15 | COMPANY | RECRUITER | 1:N | A company employs many recruiters. Each recruiter belongs to one company | RECRUITER.company_id (FK) |
| R16 | USER_ACCOUNT | RECRUITER | 1:1 | A recruiter has exactly one login account | RECRUITER.user_id (FK, unique) |
| R17 | RECRUITER | JOB | 1:N | A recruiter manages many jobs. Each job is posted by one recruiter | JOB.recruiter_id (FK) |
| R18 | JOB | SKILL | M:N | A job requires many skills. A skill is required by many jobs | JOB_SKILL (job_id, skill_id) |
| R19 | PROFICIENCY_LEVEL | JOB_SKILL | 1:N | One level is the minimum for many job requirements | JOB_SKILL.min_level_id (FK) |
| R20 | REVIEW_STATUS | COMPANY | 1:N | One status applies to many companies | COMPANY.status_id (FK) |
| R21 | REVIEW_STATUS | JOB | 1:N | One status applies to many jobs | JOB.status_id (FK) |
| R22 | USER_ACCOUNT | COMPANY | 1:N | An admin reviews many companies | COMPANY.reviewed_by (FK) |
| R23 | USER_ACCOUNT | JOB | 1:N | An admin reviews many jobs | JOB.reviewed_by (FK) |
| R24 | STUDENT | JOB | M:N | A student is matched with many jobs, many times. A job is matched with many students | JOB_MATCH (match_id, with student_id and job_id as FKs) |
| R25 | MATCH_CONFIG | JOB_MATCH | 1:N | One configuration is used by many calculations | JOB_MATCH.config_id (FK) |
| R26 | JOB_MATCH | JOB_MATCH_DETAIL | 1:N | One calculation has one detail row per required skill | JOB_MATCH_DETAIL.match_id (FK) |
| R27 | SKILL | JOB_MATCH_DETAIL | 1:N | One skill appears in many match details | JOB_MATCH_DETAIL.skill_id (FK) |
| R28 | STUDENT | APPLICATION | 1:N | A student submits many applications | APPLICATION.student_id (FK) |
| R29 | JOB | APPLICATION | 1:N | A job receives many applications | APPLICATION.job_id (FK) |
| R30 | JOB_MATCH | APPLICATION | 1:N (optional) | One match result can be attached to an application | APPLICATION.match_id (FK, can be empty) |
| R31 | APPLICATION | APPLICATION_HISTORY | 1:N | An application has many history records | APPLICATION_HISTORY.application_id (FK) |
| R32 | APPLICATION_STAGE | APPLICATION_HISTORY | 1:N | One stage appears in many history records | APPLICATION_HISTORY.stage_id (FK) |
| R33 | USER_ACCOUNT | APPLICATION_HISTORY | 1:N | A user makes many stage changes | APPLICATION_HISTORY.changed_by (FK) |
| R34 | APPLICATION | INTERVIEW | 1:N | An application has many interview rounds | INTERVIEW.application_id (FK) |
| R35 | APPLICATION | PLACEMENT | 1:0..1 | An application results in zero or one placement | PLACEMENT.application_id (FK, unique) |

Note: JOB_MATCH_DETAIL also points to PROFICIENCY_LEVEL three times (required, student and evidence levels), and APPLICATION has the unique pair (student_id, job_id).

## Part 3: Second Halves of Many-to-Many Links and Level Links

Rows R7, R8, R9, R10, R18 and R24 are many-to-many (M:N). In the ER diagram each one is drawn as two one-to-many links that meet at the middle (associative) table. Part 1 and Part 2 list the first link, and this part lists the second link. The last three rows are the level links from JOB_MATCH_DETAIL.

| ID | Entity A | Entity B | Cardinality | Meaning | Implemented by |
|---|---|---|---|---|---|
| R36 | SKILL | STUDENT_SKILL | 1:N | A skill appears in many declared-skill rows (second half of R7) | STUDENT_SKILL.skill_id (FK) |
| R37 | SKILL | PROJECT_SKILL | 1:N | A skill appears in many project-skill rows (second half of R8) | PROJECT_SKILL.skill_id (FK) |
| R38 | SKILL | CERTIFICATION_SKILL | 1:N | A skill appears in many certification-skill rows (second half of R9) | CERTIFICATION_SKILL.skill_id (FK) |
| R39 | CERTIFICATION | STUDENT_CERTIFICATION | 1:N | A certification appears in many student-certification rows (second half of R10) | STUDENT_CERTIFICATION.certification_id (FK) |
| R40 | SKILL | JOB_SKILL | 1:N | A skill appears in many job-requirement rows (second half of R18) | JOB_SKILL.skill_id (FK) |
| R41 | JOB | JOB_MATCH | 1:N | A job appears in many match calculations (second half of R24) | JOB_MATCH.job_id (FK) |
| R42 | PROFICIENCY_LEVEL | JOB_MATCH_DETAIL | 1:N | One level is the required level in many match details | JOB_MATCH_DETAIL.required_level_id (FK) |
| R43 | PROFICIENCY_LEVEL | JOB_MATCH_DETAIL | 1:N (optional) | One level is the student's declared level in many match details. Empty if the student lacked the skill | JOB_MATCH_DETAIL.student_level_id (FK, can be empty) |
| R44 | PROFICIENCY_LEVEL | JOB_MATCH_DETAIL | 1:N (optional) | One level is the evidence-supported level in many match details. Empty if no evidence existed | JOB_MATCH_DETAIL.evidence_level_id (FK, can be empty) |