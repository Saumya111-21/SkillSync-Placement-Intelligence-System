# Normalization Report

## Part 1: Concepts

### Functional dependency (FD)
A -> B means that if you know the value of A, there is exactly one possible value of B.
Example: student_id -> full_name. One student_id belongs to one name.
The reverse is usually false: full_name -> student_id is not true, because two students can share a name.

### Keys
- Superkey: any set of columns that identifies a row.
- Candidate key: a superkey with no unnecessary column.
- Primary key: the candidate key we choose.
- Prime attribute: a column that belongs to some candidate key.
- Non-prime attribute: a column that belongs to no candidate key.

### Normal forms
| Form | Rule |
|---|---|
| 1NF | Each cell holds one value. No lists. No repeating columns |
| 2NF | In 1NF, and no non-prime column depends on only part of a candidate key |
| 3NF | In 2NF, and no non-prime column depends on another non-prime column |
| BCNF | For every FD A -> B, A is a superkey |

### Anomalies
- Insertion anomaly: a fact cannot be stored without another unrelated fact.
- Update anomaly: one fact is stored many times, so a change must be made in many rows.
- Deletion anomaly: deleting one fact also deletes another unrelated fact.

### How we check each table
1. List the candidate keys.
2. List every functional dependency that really holds in the business rules.
3. Test 1NF, then 2NF, then 3NF, then BCNF.
4. If a test fails, split the table and repeat.
5. A table with a single-column key cannot have a partial dependency, so 2NF holds automatically for it.

## Part 2: Worked Example (simplified student sheet)

### Step 0: Unnormalized table (breaks 1NF)
One sheet where the skills of a student are typed as a list in one cell.

| student_id | student_name | course_name | department_name | skills |
|---|---|---|---|---|
| S1 | Asha | B.Tech CSE | Computer Science | Python, SQL |
| S2 | Ravi | B.Tech CSE | Computer Science | SQL |

Problem: the skills cell holds several values. We cannot search "who knows SQL" reliably, and we cannot store a level for each skill.

### Step 1: First Normal Form (1NF)
Rule: one value per cell. We create one row per student and skill, and add the level.

Table SHEET_1NF (student_id, student_name, course_name, department_name, skill_name, declared_level)

| student_id | student_name | course_name | department_name | skill_name | declared_level |
|---|---|---|---|---|---|
| S1 | Asha | B.Tech CSE | Computer Science | Python | 3 |
| S1 | Asha | B.Tech CSE | Computer Science | SQL | 2 |
| S2 | Ravi | B.Tech CSE | Computer Science | SQL | 4 |

Candidate key: (student_id, skill_name)

Functional dependencies:
- FD1: student_id -> student_name, course_name
- FD2: course_name -> department_name
- FD3: (student_id, skill_name) -> declared_level

Anomalies still present:
- Update: if the department is renamed, every row of every student in that course must change.
- Insertion: we cannot store a new course or a new student until that student has a skill.
- Deletion: deleting the only skill row of S2 also deletes the fact that S2 exists.

### Step 2: Second Normal Form (2NF)
Rule: no column may depend on only part of the key.
Test: FD1 says student_id alone determines student_name, course_name (and through them department_name). student_id is only part of the key (student_id, skill_name). This is a partial dependency, so SHEET_1NF is not in 2NF.

Fix: move the columns that depend on student_id into their own table.

STUDENT_2 (student_id, student_name, course_name, department_name). Key: student_id
STUDENT_SKILL (student_id, skill_name, declared_level). Key: (student_id, skill_name)

| student_id | student_name | course_name | department_name |
|---|---|---|---|
| S1 | Asha | B.Tech CSE | Computer Science |
| S2 | Ravi | B.Tech CSE | Computer Science |

| student_id | skill_name | declared_level |
|---|---|---|
| S1 | Python | 3 |
| S1 | SQL | 2 |
| S2 | SQL | 4 |

STUDENT_SKILL is in 2NF: declared_level needs both parts of the key.
STUDENT_2 is in 2NF: its key has one column, so a partial dependency is impossible.
But STUDENT_2 still repeats "Computer Science" for every student in the course.

### Step 3: Third Normal Form (3NF)
Rule: no non-key column may depend on another non-key column.
Test: in STUDENT_2, student_id -> course_name and course_name -> department_name. So department_name depends on the key only through course_name. This is a transitive dependency, so STUDENT_2 is not in 3NF.

Fix: move the course facts into their own table.

STUDENT (student_id, student_name, course_name). Key: student_id
COURSE (course_name, department_name). Key: course_name

| student_id | student_name | course_name |
|---|---|---|
| S1 | Asha | B.Tech CSE |
| S2 | Ravi | B.Tech CSE |

| course_name | department_name |
|---|---|
| B.Tech CSE | Computer Science |

Now "Computer Science" is stored once. A department rename is one update, and a new course can be added before any student joins it.

### Step 4: Boyce-Codd Normal Form (BCNF)
Rule: for every FD A -> B, A must be a superkey.
- STUDENT: student_id -> student_name, course_name. student_id is the key. OK.
- COURSE: course_name -> department_name. course_name is the key. OK.
- STUDENT_SKILL: (student_id, skill_name) -> declared_level. The left side is the key. OK.
All three tables are in BCNF.

### Link to the real SkillSync design
- COURSE and DEPARTMENT are separate tables, and STUDENT keeps only course_id. The department is found through COURSE.
- STUDENT_SKILL is a separate table with the key (student_id, skill_id).
- We use numeric ids instead of names as keys, because names can change or repeat.

## Part 3: Normalization of the SkillSync Tables

Each table is tested on its own. Functional dependencies (FDs) come from the business rules in the entity dictionary, not from guesses. 1NF holds for every table because each column holds a single value and no column is a list.

### Group 1: Accounts and Academics

### Table: USER_ACCOUNT
Columns: user_id, email, password_hash, role, is_active, created_at
Candidate keys: user_id, email
FDs:
- user_id -> email, password_hash, role, is_active, created_at
- email -> user_id, password_hash, role, is_active, created_at
2NF: both candidate keys have one column, so a partial dependency is impossible.
3NF: the only non-key columns depend directly on a candidate key. No non-key column determines another.
BCNF: the left side of every FD is a candidate key. Result: BCNF.

### Table: DEPARTMENT
Columns: department_id, department_name
Candidate keys: department_id, department_name
FDs:
- department_id -> department_name
- department_name -> department_id
2NF, 3NF: there are no non-prime columns.
BCNF: both left sides are candidate keys. Result: BCNF.

### Table: COURSE
Columns: course_id, department_id, course_name, duration_years
Candidate keys: course_id, (department_id, course_name)
FDs:
- course_id -> department_id, course_name, duration_years
- (department_id, course_name) -> course_id, duration_years
2NF: the only non-prime column is duration_years. It depends on the whole of (department_id, course_name), not on one part. We do NOT assume course_name alone fixes duration_years, because two departments could offer a course with the same name but a different length.
3NF: duration_years depends directly on a candidate key.
BCNF: both left sides are candidate keys. Result: BCNF.

### Table: STUDENT
Columns: student_id, user_id, course_id, enrollment_no, full_name, phone, admission_year
Candidate keys: student_id, user_id, enrollment_no
FDs:
- student_id -> user_id, course_id, enrollment_no, full_name, phone, admission_year
- user_id -> student_id
- enrollment_no -> student_id
We do not assume that phone, full_name or course_id determine anything, because many students can share a course, a name or a phone number.
2NF: every candidate key has one column.
3NF: the non-prime columns (course_id, full_name, phone, admission_year) do not determine each other.
BCNF: every FD has a candidate key on the left. Result: BCNF.
Design note: department is not stored here. If it were, we would get course_id -> department_id, a transitive dependency that breaks 3NF. The department is found through COURSE.

### Table: ACADEMIC_RECORD
Columns: record_id, student_id, semester_no, sgpa
Candidate keys: record_id, (student_id, semester_no)
FDs:
- record_id -> student_id, semester_no, sgpa
- (student_id, semester_no) -> record_id, sgpa
2NF: sgpa depends on the whole of (student_id, semester_no).
3NF: sgpa depends directly on a candidate key.
BCNF: both left sides are candidate keys. Result: BCNF.
Design note: overall CGPA is NOT stored in this table. It would depend on student_id alone, which is only part of the key (student_id, semester_no). That is a partial dependency and would break 2NF. It would also go out of date when a new semester is added, so we calculate it with a query.

### Group 1 summary

| Table | Candidate keys | Highest normal form verified |
|---|---|---|
| USER_ACCOUNT | user_id; email | BCNF |
| DEPARTMENT | department_id; department_name | BCNF |
| COURSE | course_id; (department_id, course_name) | BCNF |
| STUDENT | student_id; user_id; enrollment_no | BCNF |
| ACADEMIC_RECORD | record_id; (student_id, semester_no) | BCNF |

### Group 2: Skills, Projects and Certifications

### Table: SKILL_CATEGORY
Columns: category_id, category_name
Candidate keys: category_id, category_name
FDs:
- category_id -> category_name
- category_name -> category_id
2NF, 3NF: there are no non-prime columns.
BCNF: both left sides are candidate keys. Result: BCNF.

### Table: SKILL
Columns: skill_id, category_id, skill_name
Candidate keys: skill_id, skill_name
FDs:
- skill_id -> category_id, skill_name
- skill_name -> skill_id, category_id
We do not assume that category_id determines anything, because one category groups many skills.
2NF: both candidate keys have one column.
3NF: the only non-prime column is category_id. It does not determine any other column.
BCNF: both left sides are candidate keys. Result: BCNF.
Design note: category_name is not stored here. It would give skill_id -> category_id -> category_name, a transitive dependency that breaks 3NF. The name is found through SKILL_CATEGORY.

### Table: PROFICIENCY_LEVEL
Columns: level_id, level_name, min_score, max_score
Candidate keys: level_id, level_name, min_score, max_score
FDs:
- level_id -> level_name, min_score, max_score
- level_name -> level_id, min_score, max_score
- min_score -> level_id, level_name, max_score
- max_score -> level_id, level_name, min_score
The last two FDs hold only because of a business rule: each level has its own score range, and ranges do not overlap, so a given min_score or max_score belongs to exactly one level. In Phase 4 this rule is enforced with UNIQUE constraints on min_score and max_score and a CHECK that min_score <= max_score. Without that rule these two FDs would not hold.
2NF: all candidate keys have one column.
3NF, BCNF: every non-prime column set is empty, because all four columns belong to a candidate key. The left side of every FD is a candidate key. Result: BCNF.
Design note: this table stores the score ranges, so SKILL_ASSESSMENT can derive the level from score_percent without storing it.

### Table: STUDENT_SKILL
Columns: student_id, skill_id, declared_level_id, updated_at
Candidate key: (student_id, skill_id)
FDs:
- (student_id, skill_id) -> declared_level_id, updated_at
The declared level belongs to the pair. A student can have different levels in different skills, and one skill can have different levels for different students. So neither student_id alone nor skill_id alone determines declared_level_id.
2NF: no non-prime column depends on only part of the key. Result: 2NF holds.
3NF: declared_level_id and updated_at do not determine each other.
BCNF: the only FD has the full key on the left. Result: BCNF.
Design note: skill_name is not stored here. It would depend on skill_id alone, which is only part of the key, so it would break 2NF. Evidence from projects, certifications and assessments is not stored here either. It is derived through a view, so the same fact is never stored twice.

### Table: STUDENT_PROJECT
Columns: project_id, student_id, title, description, start_date, end_date, project_url
Candidate key: project_id
FDs:
- project_id -> student_id, title, description, start_date, end_date, project_url
We do not assume that (student_id, title) is unique, because no business rule says a student cannot reuse a title. We also do not assume that student_id or title alone determines anything.
2NF: the key has one column.
3NF: no non-key column determines another.
BCNF: the only FD has the key on the left. Result: BCNF.

### Table: PROJECT_SKILL
Columns: project_id, skill_id
Candidate key: (project_id, skill_id)
FDs: none other than the trivial ones. Every column is part of the key.
2NF, 3NF: there are no non-prime columns.
BCNF: there are no non-trivial FDs. Result: BCNF.
Design note: this is the associative table that resolves the many-to-many link between projects and skills.

### Table: CERTIFICATION
Columns: certification_id, certification_name, issuing_body
Candidate keys: certification_id, (certification_name, issuing_body)
FDs:
- certification_id -> certification_name, issuing_body
- (certification_name, issuing_body) -> certification_id
Neither certification_name alone nor issuing_body alone determines anything, because two issuers can offer certifications with the same name.
2NF, 3NF: there are no non-prime columns.
BCNF: both left sides are candidate keys. Result: BCNF.

### Table: CERTIFICATION_SKILL
Columns: certification_id, skill_id
Candidate key: (certification_id, skill_id)
FDs: none other than the trivial ones. Every column is part of the key.
2NF, 3NF: there are no non-prime columns.
BCNF: there are no non-trivial FDs. Result: BCNF.
Design note: this table was added so the system knows which skills a certification supports. Without it, evidence from certifications could not be tracked.

### Table: STUDENT_CERTIFICATION
Columns: student_id, certification_id, issue_date, credential_id, credential_url
Candidate key: (student_id, certification_id)
FDs:
- (student_id, certification_id) -> issue_date, credential_id, credential_url
We do not assume that credential_id is unique or that it determines credential_url, because no business rule says so. Different issuers could reuse the same credential number.
2NF: the three non-prime columns describe this student's copy of this certification, so they depend on the whole key. No column such as certification_name is stored here, which would depend on certification_id alone.
3NF: issue_date, credential_id and credential_url do not determine each other.
BCNF: the only FD has the full key on the left. Result: BCNF.

### Table: SKILL_ASSESSMENT
Columns: assessment_id, student_id, skill_id, score_percent, taken_at
Candidate key: assessment_id
FDs:
- assessment_id -> student_id, skill_id, score_percent, taken_at
We do not assume that (student_id, skill_id, taken_at) is a key, because no business rule forbids two attempts at the same moment. One row is kept per attempt, so repeated attempts are preserved.
2NF: the key has one column.
3NF: score_percent and taken_at do not determine each other or any other column.
BCNF: the only FD has the key on the left. Result: BCNF.
Design note (Option A): the assessed level is NOT stored in this table. It is calculated from score_percent using the ranges min_score and max_score in PROFICIENCY_LEVEL. If a column assessed_level_id existed, we would get score_percent -> assessed_level_id, where score_percent is not a key. That is a transitive dependency and breaks 3NF and BCNF. It would also cause an update anomaly: changing a score range would leave old rows with the wrong level.

### Group 2 summary

| Table | Candidate keys | Highest normal form verified |
|---|---|---|
| SKILL_CATEGORY | category_id; category_name | BCNF |
| SKILL | skill_id; skill_name | BCNF |
| PROFICIENCY_LEVEL | level_id; level_name; min_score; max_score | BCNF (relies on the non-overlapping score range rule, enforced by constraints) |
| STUDENT_SKILL | (student_id, skill_id) | BCNF |
| STUDENT_PROJECT | project_id | BCNF |
| PROJECT_SKILL | (project_id, skill_id) | BCNF |
| CERTIFICATION | certification_id; (certification_name, issuing_body) | BCNF |
| CERTIFICATION_SKILL | (certification_id, skill_id) | BCNF |
| STUDENT_CERTIFICATION | (student_id, certification_id) | BCNF |
| SKILL_ASSESSMENT | assessment_id | BCNF |

### Group 3: Companies, Recruiters and Jobs

### Table: REVIEW_STATUS
Columns: status_id, status_name
Candidate keys: status_id, status_name
FDs:
- status_id -> status_name
- status_name -> status_id
2NF, 3NF: there are no non-prime columns.
BCNF: both left sides are candidate keys. Result: BCNF.

### Table: COMPANY
Columns: company_id, company_name, industry, website, status_id, reviewed_by, reviewed_at
Candidate keys: company_id, company_name
FDs:
- company_id -> company_name, industry, website, status_id, reviewed_by, reviewed_at
- company_name -> company_id, industry, website, status_id, reviewed_by, reviewed_at
We do not assume that website is unique, because no business rule says two company records cannot share a website. We do not assume that industry determines anything, because many companies share an industry.
2NF: both candidate keys have one column.
3NF: the non-prime columns (industry, website, status_id, reviewed_by, reviewed_at) do not determine each other.
BCNF: both left sides are candidate keys. Result: BCNF.
Design note: the rules "reviewed_by and reviewed_at are empty until the company is reviewed" and "reviewed_by must be an admin" are not functional dependencies. A foreign key cannot check a user's role. They are enforced in Phase 4 with a CHECK constraint and a trigger.

### Table: RECRUITER
Columns: recruiter_id, user_id, company_id, full_name, designation
Candidate keys: recruiter_id, user_id
FDs:
- recruiter_id -> user_id, company_id, full_name, designation
- user_id -> recruiter_id, company_id, full_name, designation
We do not assume that company_id determines anything, because one company employs many recruiters. We do not assume that designation determines anything, because many recruiters share a designation.
2NF: both candidate keys have one column.
3NF: company_id, full_name and designation do not determine each other.
BCNF: both left sides are candidate keys. Result: BCNF.
Design note: company_name is not stored here. It would give recruiter_id -> company_id -> company_name, a transitive dependency that breaks 3NF. The name is found through COMPANY.

### Table: JOB
Columns: job_id, recruiter_id, title, description, job_type, location, min_cgpa, application_deadline, is_open, status_id, reviewed_by, reviewed_at, posted_at
Candidate key: job_id
FDs:
- job_id -> recruiter_id, title, description, job_type, location, min_cgpa, application_deadline, is_open, status_id, reviewed_by, reviewed_at, posted_at
We do not assume that title, location or recruiter_id determines anything. One recruiter posts many jobs, and many jobs can share a title or a location.
2NF: the key has one column.
3NF: no non-key column determines another.
BCNF: the only FD has the key on the left. Result: BCNF.
Design note: company_id is not stored here. It would give job_id -> recruiter_id -> company_id, a transitive dependency that breaks 3NF. The company is found through RECRUITER. As in COMPANY, the review rules are enforced by a CHECK constraint and a trigger in Phase 4. The minimum CGPA is an eligibility filter only and is not part of the skill score.

### Table: JOB_SKILL
Columns: job_id, skill_id, is_mandatory, min_level_id
Candidate key: (job_id, skill_id)
FDs:
- (job_id, skill_id) -> is_mandatory, min_level_id
Whether a skill is mandatory, and the level it needs, belong to the skill for that job. The same skill can be mandatory in one job and preferred in another, so neither job_id alone nor skill_id alone determines is_mandatory or min_level_id.
2NF: no non-prime column depends on only part of the key. Result: 2NF holds.
3NF: is_mandatory and min_level_id do not determine each other.
BCNF: the only FD has the full key on the left. Result: BCNF.
Design note: skill_name is not stored here. It would depend on skill_id alone, which is only part of the key, so it would break 2NF.

### Group 3 summary

| Table | Candidate keys | Highest normal form verified |
|---|---|---|
| REVIEW_STATUS | status_id; status_name | BCNF |
| COMPANY | company_id; company_name | BCNF |
| RECRUITER | recruiter_id; user_id | BCNF |
| JOB | job_id | BCNF |
| JOB_SKILL | (job_id, skill_id) | BCNF |

### Group 4: Matching, Applications, Interviews and Placements

### Table: APPLICATION_STAGE
Columns: stage_id, stage_name, stage_order
Candidate keys: stage_id, stage_name
FDs:
- stage_id -> stage_name, stage_order
- stage_name -> stage_id, stage_order
We do not assume that stage_order is unique, so stage_order is not treated as a key and determines nothing.
2NF, 3NF: the only non-prime column is stage_order, and it determines no other column.
BCNF: both left sides are candidate keys. Result: BCNF.

### Table: APPLICATION
Columns: application_id, student_id, job_id, match_id, applied_at
Candidate keys: application_id, (student_id, job_id)
FDs:
- application_id -> student_id, job_id, match_id, applied_at
- (student_id, job_id) -> application_id, match_id, applied_at
Business rule: a student applies to a job only once, so (student_id, job_id) is unique.
Note on match_id: a match result belongs to exactly one student and one job. So when match_id is present it determines (student_id, job_id), and therefore the whole row. This makes match_id a candidate key whenever it is not empty. In Phase 4 this is enforced with a UNIQUE constraint on match_id and a composite foreign key (match_id, student_id, job_id) that forces the attached match to belong to the same student and job. A consequence: one match result can be attached to at most one application. Relationship R30 in relationships.md says 1:N and should read 1:0..1. It will be corrected in the clean-up at the end of Phase 3.
2NF: no non-prime column depends on only part of a candidate key.
3NF: no non-prime column determines another non-prime column.
BCNF: the left side of every FD is a candidate key. Result: BCNF.
Design note: the current stage is NOT stored here. It is the latest row in APPLICATION_HISTORY and is found through a view. A stored copy could disagree with the history. The company is also not stored, because it is found through JOB and RECRUITER.

### Table: APPLICATION_HISTORY
Columns: history_id, application_id, stage_id, changed_by, changed_at, remarks
Candidate key: history_id
FDs:
- history_id -> application_id, stage_id, changed_by, changed_at, remarks
We do not assume that (application_id, changed_at) is unique, because no business rule forbids two changes in the same instant.
2NF: the key has one column.
3NF: no non-key column determines another.
BCNF: the only FD has the key on the left. Result: BCNF.

### Table: INTERVIEW
Columns: interview_id, application_id, round_no, scheduled_at, mode, outcome
Candidate keys: interview_id, (application_id, round_no)
FDs:
- interview_id -> application_id, round_no, scheduled_at, mode, outcome
- (application_id, round_no) -> interview_id, scheduled_at, mode, outcome
Business rule: an application has each interview round number only once.
2NF: scheduled_at, mode and outcome depend on the whole of (application_id, round_no), not on one part.
3NF: scheduled_at, mode and outcome do not determine each other.
BCNF: both left sides are candidate keys. Result: BCNF.

### Table: PLACEMENT
Columns: placement_id, application_id, offer_status, package_lpa, offer_date, joining_date
Candidate keys: placement_id, application_id
FDs:
- placement_id -> application_id, offer_status, package_lpa, offer_date, joining_date
- application_id -> placement_id, offer_status, package_lpa, offer_date, joining_date
Business rule: one application results in at most one placement, so application_id is unique.
2NF: both candidate keys have one column.
3NF: the non-prime columns do not determine each other. We do not assume that package_lpa determines anything.
BCNF: both left sides are candidate keys. Result: BCNF.
Design note: student, job and company are not stored here. They are found through APPLICATION. Storing them would create transitive dependencies through application_id.

### Table: MATCH_CONFIG
Columns: config_id, version_label, mandatory_weight, description, created_at
Candidate keys: config_id, version_label
FDs:
- config_id -> version_label, mandatory_weight, description, created_at
- version_label -> config_id, mandatory_weight, description, created_at
2NF: both candidate keys have one column.
3NF: no non-prime column determines another.
BCNF: both left sides are candidate keys. Result: BCNF.
Design note: the original design also stored preferred_weight. Because the two weights must add up to 1, we would have mandatory_weight -> preferred_weight, where mandatory_weight is not a key. That breaks 3NF, so preferred_weight was removed. It is calculated as 1 - mandatory_weight. A CHECK constraint in Phase 4 keeps mandatory_weight between 0 and 1.

### Table: JOB_MATCH
Columns: match_id, student_id, job_id, config_id, mandatory_coverage, preferred_coverage, overall_score, calculated_at
Candidate key: match_id
FDs:
- match_id -> student_id, job_id, config_id, mandatory_coverage, preferred_coverage, overall_score, calculated_at
- (config_id, mandatory_coverage, preferred_coverage) -> overall_score
The second FD comes from the scoring rule: overall_score = mandatory_weight x mandatory_coverage + preferred_weight x preferred_coverage, and the weights are fixed by config_id. Its left side is not a key.
2NF: the key has one column, so a partial dependency is impossible.
3NF: NOT satisfied. overall_score depends on non-key columns.
BCNF: NOT satisfied for the same reason.
Result: 2NF.
Deliberate denormalization: overall_score and the two coverage columns are stored as a result snapshot. The coverage values can also be recomputed from JOB_MATCH_DETAIL rows. We keep them for these reasons:
- Old results must stay reproducible even if the matching rules change later.
- A student can compare a past score with a current one without recalculating history.
- Phase 10 measures stored values against recalculated values.
Controls: rows are written once and never edited (a Phase 4 trigger blocks UPDATE), so the stored values cannot become stale. A second trigger checks at insert time that overall_score equals the calculated value. The score is a skill-coverage indicator, never a hiring probability.

### Table: JOB_MATCH_DETAIL
Columns: match_id, skill_id, was_mandatory, required_level_id, student_level_id, evidence_level_id, is_matched
Candidate key: (match_id, skill_id)
FDs:
- (match_id, skill_id) -> was_mandatory, required_level_id, student_level_id, evidence_level_id, is_matched
- (required_level_id, student_level_id, evidence_level_id) -> is_matched
The second FD comes from the matching rule, which compares the student's levels with the required level. Its left side is not a key.
2NF: holds. Each non-prime column describes one skill within one match. match_id alone does not determine them, because a match has many skills. skill_id alone does not determine them, because many matches include the same skill.
3NF: NOT satisfied. is_matched depends on non-key columns.
BCNF: NOT satisfied for the same reason.
Result: 2NF.
Deliberate snapshot: was_mandatory, required_level_id, student_level_id and evidence_level_id are copies of what was true at calculation time. They are not redundant with JOB_SKILL or STUDENT_SKILL, because those tables change over time and these rows must not. is_matched is derived from them and is stored for the same reproducibility reasons as in JOB_MATCH. Missing skills are the rows where is_matched is false. The same controls apply: rows are insert-only, and a trigger checks is_matched at insert time.

### Group 4 summary

| Table | Candidate keys | Highest normal form verified |
|---|---|---|
| MATCH_CONFIG | config_id; version_label | BCNF |
| JOB_MATCH | match_id | 2NF (deliberate denormalization, see above) |
| JOB_MATCH_DETAIL | (match_id, skill_id) | 2NF (deliberate denormalization, see above) |
| APPLICATION_STAGE | stage_id; stage_name | BCNF |
| APPLICATION | application_id; (student_id, job_id) | BCNF |
| APPLICATION_HISTORY | history_id | BCNF |
| INTERVIEW | interview_id; (application_id, round_no) | BCNF |
| PLACEMENT | placement_id; application_id | BCNF |

## Part 4: Overall Result

Of the 28 tables, 26 are verified in BCNF and 2 (JOB_MATCH and JOB_MATCH_DETAIL) are in 2NF because they deliberately store calculated result snapshots. These two are documented, constrained by insert-only triggers, and measured in the Phase 10 experiments.
