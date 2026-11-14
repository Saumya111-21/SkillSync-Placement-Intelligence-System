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
| R14 | PROFICIENCY_LEVEL | SKILL_ASSESSMENT | 1:N | One level is the result of many assessments | SKILL_ASSESSMENT.assessed_level_id (FK) |