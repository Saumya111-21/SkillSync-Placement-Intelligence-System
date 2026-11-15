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