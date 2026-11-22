-- SkillSync SAMPLE DATA, part 1: reference data
-- ALL DATA IN THE SAMPLE FILES IS SYNTHETIC (invented). It is not real
-- student, company or job data.

BEGIN;

INSERT INTO department (department_name) VALUES
    ('Computer Science'),
    ('Information Technology'),
    ('Electronics and Communication'),
    ('Mechanical Engineering');

INSERT INTO course (department_id, course_name, duration_years)
SELECT d.department_id, v.cname, v.yrs
FROM (VALUES
    ('Computer Science',              'B.Tech CSE',                 4),
    ('Computer Science',              'B.Tech CSE (Data Science)',  4),
    ('Computer Science',              'M.Tech CSE',                 2),
    ('Information Technology',        'B.Tech IT',                  4),
    ('Electronics and Communication', 'B.Tech ECE',                 4),
    ('Mechanical Engineering',        'B.Tech Mechanical',          4)
) AS v(dname, cname, yrs)
JOIN department d ON d.department_name = v.dname;

INSERT INTO skill (category_id, skill_name)
SELECT c.category_id, v.sname
FROM (VALUES
    ('Programming',      'Python'),
    ('Programming',      'Java'),
    ('Programming',      'C++'),
    ('Programming',      'JavaScript'),
    ('Programming',      'R'),
    ('Database',         'SQL'),
    ('Database',         'PostgreSQL'),
    ('Database',         'MySQL'),
    ('Database',         'MongoDB'),
    ('Data Analysis',    'Statistics'),
    ('Data Analysis',    'Excel'),
    ('Data Analysis',    'Machine Learning Basics'),
    ('Data Analysis',    'Data Cleaning'),
    ('Visualization',    'Power BI'),
    ('Visualization',    'Tableau'),
    ('Visualization',    'Data Visualization'),
    ('Web Development',  'HTML and CSS'),
    ('Web Development',  'React'),
    ('Web Development',  'Node.js'),
    ('Web Development',  'Flask'),
    ('Cloud and DevOps', 'Git'),
    ('Cloud and DevOps', 'Docker'),
    ('Cloud and DevOps', 'AWS Basics'),
    ('Cloud and DevOps', 'Linux'),
    ('Tools',            'Jira'),
    ('Tools',            'Postman'),
    ('Soft Skill',       'Communication'),
    ('Soft Skill',       'Teamwork'),
    ('Soft Skill',       'Problem Solving'),
    ('Soft Skill',       'Presentation Skills')
) AS v(cat, sname)
JOIN skill_category c ON c.category_name = v.cat;

INSERT INTO certification (certification_name, issuing_body) VALUES
    ('Google Data Analytics Professional Certificate', 'Coursera'),
    ('Microsoft Power BI Data Analyst',                'Microsoft'),
    ('AWS Cloud Practitioner',                         'Amazon Web Services'),
    ('Oracle Database SQL Certified Associate',        'Oracle'),
    ('IBM Data Science Professional Certificate',      'Coursera'),
    ('Tableau Desktop Specialist',                     'Tableau'),
    ('Python for Everybody',                           'Coursera'),
    ('MongoDB Associate Developer',                    'MongoDB');

-- Which skills each certification covers (assumptions made for this sample).
INSERT INTO certification_skill (certification_id, skill_id)
SELECT c.certification_id, s.skill_id
FROM (VALUES
    ('Google Data Analytics Professional Certificate', 'SQL'),
    ('Google Data Analytics Professional Certificate', 'Excel'),
    ('Google Data Analytics Professional Certificate', 'Data Cleaning'),
    ('Google Data Analytics Professional Certificate', 'Tableau'),
    ('Google Data Analytics Professional Certificate', 'R'),
    ('Microsoft Power BI Data Analyst',                'Power BI'),
    ('Microsoft Power BI Data Analyst',                'Data Visualization'),
    ('AWS Cloud Practitioner',                         'AWS Basics'),
    ('Oracle Database SQL Certified Associate',        'SQL'),
    ('IBM Data Science Professional Certificate',      'Python'),
    ('IBM Data Science Professional Certificate',      'Machine Learning Basics'),
    ('IBM Data Science Professional Certificate',      'SQL'),
    ('IBM Data Science Professional Certificate',      'Statistics'),
    ('Tableau Desktop Specialist',                     'Tableau'),
    ('Tableau Desktop Specialist',                     'Data Visualization'),
    ('Python for Everybody',                           'Python'),
    ('MongoDB Associate Developer',                    'MongoDB')
) AS v(cname, sname)
JOIN certification c ON c.certification_name = v.cname
JOIN skill s         ON s.skill_name         = v.sname;

COMMIT;