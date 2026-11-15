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