-- SkillSync SAMPLE DATA, part 5: declared skills of the students
-- ALL DATA IN THE SAMPLE FILES IS SYNTHETIC (invented).
-- Levels: 1 Beginner, 2 Intermediate, 3 Advanced, 4 Expert (declared by the student).

BEGIN;

INSERT INTO student_skill (student_id, skill_id, declared_level_id)
SELECT st.student_id, sk.skill_id, v.lvl
FROM (VALUES
    -- Aarav Sharma
    ('CS23-001', 'Python', 3),
    ('CS23-001', 'Java', 3),
    ('CS23-001', 'SQL', 2),
    ('CS23-001', 'Git', 3),
    ('CS23-001', 'Flask', 2),
    ('CS23-001', 'PostgreSQL', 2),
    ('CS23-001', 'Problem Solving', 3),
    ('CS23-001', 'Teamwork', 3),
    -- Diya Patel
    ('DS23-002', 'Python', 3),
    ('DS23-002', 'SQL', 3),
    ('DS23-002', 'Excel', 3),
    ('DS23-002', 'Power BI', 2),
    ('DS23-002', 'Statistics', 3),
    ('DS23-002', 'Data Visualization', 3),
    ('DS23-002', 'Machine Learning Basics', 2),
    ('DS23-002', 'Communication', 3),
    -- Kabir Malhotra
    ('IT23-003', 'Python', 2),
    ('IT23-003', 'SQL', 3),
    ('IT23-003', 'Excel', 4),
    ('IT23-003', 'Tableau', 3),
    ('IT23-003', 'Communication', 2),
    ('IT23-003', 'MySQL', 3),
    -- Ananya Reddy
    ('DS23-004', 'Python', 4),
    ('DS23-004', 'Statistics', 3),
    ('DS23-004', 'Machine Learning Basics', 3),
    ('DS23-004', 'SQL', 3),
    ('DS23-004', 'Data Cleaning', 3),
    ('DS23-004', 'R', 2),
    ('DS23-004', 'Git', 2),
    ('DS23-004', 'Data Visualization', 2),
    -- Rahul Nair
    ('CS23-005', 'Java', 3),
    ('CS23-005', 'C++', 3),
    ('CS23-005', 'Python', 2),
    ('CS23-005', 'SQL', 2),
    ('CS23-005', 'Git', 2),
    ('CS23-005', 'Problem Solving', 3),
    ('CS23-005', 'Linux', 2),
    -- Priya Menon
    ('EC23-006', 'C++', 3),
    ('EC23-006', 'Python', 2),
    ('EC23-006', 'Linux', 3),
    ('EC23-006', 'Problem Solving', 2),
    ('EC23-006', 'Teamwork', 3),
    ('EC23-006', 'Communication', 2),
    -- Sahil Gupta
    ('ME24-007', 'Excel', 3),
    ('ME24-007', 'Python', 1),
    ('ME24-007', 'Communication', 3),
    ('ME24-007', 'Teamwork', 3),
    ('ME24-007', 'Presentation Skills', 3),
    -- Tara Bose
    ('CS24-008', 'JavaScript', 3),
    ('CS24-008', 'HTML and CSS', 3),
    ('CS24-008', 'React', 2),
    ('CS24-008', 'Node.js', 2),
    ('CS24-008', 'Git', 2),
    ('CS24-008', 'MongoDB', 2),
    ('CS24-008', 'Teamwork', 3),
    -- Yash Choudhary
    ('IT23-009', 'HTML and CSS', 2),
    ('IT23-009', 'JavaScript', 2),
    ('IT23-009', 'SQL', 2),
    ('IT23-009', 'Excel', 2),
    ('IT23-009', 'Communication', 2),
    -- Zoya Khan
    ('DS24-010', 'Python', 3),
    ('DS24-010', 'SQL', 2),
    ('DS24-010', 'Statistics', 2),
    ('DS24-010', 'Data Visualization', 2),
    ('DS24-010', 'Tableau', 2),
    ('DS24-010', 'Excel', 3),
    ('DS24-010', 'Communication', 2)
) AS v(enr, sname, lvl)
JOIN student st ON st.enrollment_no = v.enr
JOIN skill sk   ON sk.skill_name    = v.sname;

COMMIT;