# Requirements Specification

## 1. Users

| User | Description |
|---|---|
| Student | A university student who manages skills and applies for jobs |
| Recruiter | A company employee who posts jobs and reviews candidates |
| Administrator | A placement officer who manages data and views analytics |

## 2. Functional Requirements

### Student
- FR-S1: Register, log in and log out.
- FR-S2: Create and update a profile with academic information.
- FR-S3: Add skills with a proficiency level from 1 (Beginner) to 4 (Expert).
- FR-S4: Add projects and link skills to each project.
- FR-S5: Add certifications and link them to skills.
- FR-S6: Take skill assessments.
- FR-S7: View jobs with an explainable match result.
- FR-S8: See matched skills, missing skills and prioritized recommendations.
- FR-S9: Compare previous and current match results.
- FR-S10: Apply for jobs and track application stages.
- FR-S11: View placement history.

### Recruiter
- FR-R1: Register, log in and log out.
- FR-R2: Belong to one registered company.
- FR-R3: Create and manage job listings.
- FR-R4: Set mandatory and preferred skills with minimum proficiency levels.
- FR-R5: View suitable candidates with transparent match information.
- FR-R6: Review candidate projects and certifications.
- FR-R7: Update application stages and schedule interviews.

### Administrator
- FR-A1: Manage student, company and recruiter records.
- FR-A2: Review and approve or reject job postings.
- FR-A3: View department-wise placement statistics.
- FR-A4: Analyze industry skill demand versus student skill supply.
- FR-A5: Identify common student skill gaps.
- FR-A6: Track applications and placements.
- FR-A7: Generate reports.

### Skill Intelligence Engine
- FR-E1: Compare student skills with job-required skills.
- FR-E2: Identify matched and missing skills.
- FR-E3: Distinguish mandatory and preferred skills.
- FR-E4: Compare proficiency levels.
- FR-E5: Calculate a configurable match score and explain the calculation.
- FR-E6: Prioritize missing skills.
- FR-E7: Save every match result with a timestamp and keep the history.

## 3. Non-Functional Requirements

- NFR-1 Security: passwords are stored only as secure hashes, and every action checks the user's role.
- NFR-2 Privacy: sensitive personal attributes are never used in match scoring.
- NFR-3 Data integrity: keys and constraints in the database enforce the business rules.
- NFR-4 Normalization: the schema is normalized to at least 3NF, and BCNF where appropriate.
- NFR-5 Transparency: every match score can be explained and reproduced from stored data.
- NFR-6 Performance: query times are measured with EXPLAIN ANALYZE at 1,000, 10,000 and 50,000 records.
- NFR-7 Usability: the interface is clean, consistent and usable in a live demonstration.
- NFR-8 Portability: the system runs locally using free, open-source tools.
- NFR-9 Honesty: the match score is a skill-coverage indicator, not a hiring probability.

## 4. Assumptions and Constraints

- All data used for testing and experiments is synthetic and labeled as such.
- No real student data is stored.
- No machine learning, resume parsing, payments or email notifications.
- The project is developed by one student within about 18 weeks.