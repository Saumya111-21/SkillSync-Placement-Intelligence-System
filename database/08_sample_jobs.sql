-- SkillSync SAMPLE DATA, part 3: jobs and required skills
-- ALL DATA IN THE SAMPLE FILES IS SYNTHETIC (invented).
-- Deadlines are relative to the day the file is run (CURRENT_DATE + N).
-- Some jobs are deliberate test cases for the view v_open_jobs.

BEGIN;

-- Eleven jobs approved by the admin. Three of them are test cases:
--   Data Analyst Trainee  : closed (is_open = false)
--   Analytics Intern      : deadline already passed
--   Product Analyst       : its company (Orbit Labs) is still pending
INSERT INTO job (recruiter_id, title, description, job_type, location, min_cgpa,
                 application_deadline, is_open, status_id, reviewed_by, reviewed_at)
SELECT r.recruiter_id, v.title, v.descr, v.jtype, v.loc, v.cgpa,
       v.dl, v.open_flag, 2, a.user_id, now()
FROM (VALUES
    ('Meera Kapoor', 'Data Analyst',
     'Analyse business data, build reports and dashboards.',
     'full_time', 'Bengaluru', 6.5, CURRENT_DATE + 45, TRUE),
    ('Arjun Rao', 'Business Intelligence Analyst',
     'Design dashboards and metrics for business teams.',
     'full_time', 'Pune', 7.0, CURRENT_DATE + 40, TRUE),
    ('Sana Iyer', 'Junior Python Developer',
     'Build and maintain Python services with a small team.',
     'full_time', 'Hyderabad', 6.0, CURRENT_DATE + 50, TRUE),
    ('Sana Iyer', 'Backend Developer Intern',
     'Six month internship on backend APIs.',
     'internship', 'Remote', NULL, CURRENT_DATE + 30, TRUE),
    ('Vikram Singh', 'Data Science Intern',
     'Support data science projects: cleaning, modelling, reporting.',
     'internship', 'Gurugram', 7.0, CURRENT_DATE + 35, TRUE),
    ('Vikram Singh', 'Machine Learning Engineer (Entry)',
     'Train and deploy basic machine learning models.',
     'full_time', 'Noida', 7.5, CURRENT_DATE + 60, TRUE),
    ('Neha Joshi', 'Cloud Support Engineer',
     'First-line support for cloud customers.',
     'full_time', 'Chennai', 6.0, CURRENT_DATE + 55, TRUE),
    ('Rohan Das', 'Frontend Developer',
     'Build responsive web interfaces.',
     'full_time', 'Mumbai', 6.5, CURRENT_DATE + 25, TRUE),
    ('Meera Kapoor', 'Data Analyst Trainee',
     'Trainee role. Closed by the recruiter.',
     'full_time', 'Bengaluru', 6.0, CURRENT_DATE + 20, FALSE),
    ('Arjun Rao', 'Analytics Intern',
     'Internship. The application deadline has already passed.',
     'internship', 'Pune', NULL, CURRENT_DATE - 10, TRUE),
    ('Isha Verma', 'Product Analyst',
     'Approved job, but the company is still pending review.',
     'full_time', 'Delhi', 6.5, CURRENT_DATE + 30, TRUE)
) AS v(rname, title, descr, jtype, loc, cgpa, dl, open_flag)
JOIN recruiter r ON r.full_name = v.rname,
     user_account a
WHERE a.email = 'admin@example.org';

-- One job still pending review: status 1, no reviewer, no review date.
INSERT INTO job (recruiter_id, title, description, job_type, location,
                 min_cgpa, application_deadline)
SELECT r.recruiter_id, 'Full Stack Developer',
       'Pending review by the placement office.',
       'full_time', 'Mumbai', 6.5, CURRENT_DATE + 45
FROM recruiter r WHERE r.full_name = 'Rohan Das';

-- Required skills: (job, skill, mandatory?, minimum level 1 to 4)
INSERT INTO job_skill (job_id, skill_id, is_mandatory, min_level_id)
SELECT j.job_id, s.skill_id, v.mand, v.lvl
FROM (VALUES
    ('Data Analyst', 'Python',                  TRUE,  2),
    ('Data Analyst', 'SQL',                     TRUE,  3),
    ('Data Analyst', 'Excel',                   TRUE,  3),
    ('Data Analyst', 'Power BI',                TRUE,  2),
    ('Data Analyst', 'Statistics',              TRUE,  2),
    ('Data Analyst', 'Data Visualization',      FALSE, 2),
    ('Data Analyst', 'Communication',           FALSE, 2),

    ('Business Intelligence Analyst', 'SQL',                TRUE,  3),
    ('Business Intelligence Analyst', 'Power BI',           TRUE,  3),
    ('Business Intelligence Analyst', 'Excel',              TRUE,  2),
    ('Business Intelligence Analyst', 'Data Visualization', TRUE,  3),
    ('Business Intelligence Analyst', 'Tableau',            FALSE, 2),
    ('Business Intelligence Analyst', 'Communication',      FALSE, 2),

    ('Junior Python Developer', 'Python',          TRUE,  3),
    ('Junior Python Developer', 'Git',             TRUE,  2),
    ('Junior Python Developer', 'SQL',             TRUE,  2),
    ('Junior Python Developer', 'Problem Solving', TRUE,  2),
    ('Junior Python Developer', 'Flask',           FALSE, 2),
    ('Junior Python Developer', 'PostgreSQL',      FALSE, 2),

    ('Backend Developer Intern', 'Python',  TRUE,  2),
    ('Backend Developer Intern', 'SQL',     TRUE,  2),
    ('Backend Developer Intern', 'Git',     TRUE,  1),
    ('Backend Developer Intern', 'Node.js', FALSE, 1),
    ('Backend Developer Intern', 'Postman', FALSE, 1),

    ('Data Science Intern', 'Python',                  TRUE,  2),
    ('Data Science Intern', 'Statistics',              TRUE,  2),
    ('Data Science Intern', 'Machine Learning Basics', TRUE,  2),
    ('Data Science Intern', 'SQL',                     TRUE,  2),
    ('Data Science Intern', 'Data Visualization',      FALSE, 2),
    ('Data Science Intern', 'Data Cleaning',           FALSE, 2),

    ('Machine Learning Engineer (Entry)', 'Python',                  TRUE,  3),
    ('Machine Learning Engineer (Entry)', 'Machine Learning Basics', TRUE,  3),
    ('Machine Learning Engineer (Entry)', 'Statistics',              TRUE,  3),
    ('Machine Learning Engineer (Entry)', 'SQL',                     TRUE,  2),
    ('Machine Learning Engineer (Entry)', 'Git',                     TRUE,  2),
    ('Machine Learning Engineer (Entry)', 'Docker',                  FALSE, 2),

    ('Cloud Support Engineer', 'AWS Basics',      TRUE,  2),
    ('Cloud Support Engineer', 'Linux',           TRUE,  3),
    ('Cloud Support Engineer', 'Communication',   TRUE,  2),
    ('Cloud Support Engineer', 'Problem Solving', TRUE,  2),
    ('Cloud Support Engineer', 'Docker',          FALSE, 2),
    ('Cloud Support Engineer', 'Python',          FALSE, 2),

    ('Frontend Developer', 'HTML and CSS', TRUE,  3),
    ('Frontend Developer', 'JavaScript',   TRUE,  3),
    ('Frontend Developer', 'React',        TRUE,  2),
    ('Frontend Developer', 'Git',          TRUE,  2),
    ('Frontend Developer', 'Teamwork',     FALSE, 2),

    ('Full Stack Developer', 'JavaScript', TRUE,  3),
    ('Full Stack Developer', 'React',      TRUE,  2),
    ('Full Stack Developer', 'Node.js',    TRUE,  2),
    ('Full Stack Developer', 'Git',        TRUE,  2),
    ('Full Stack Developer', 'MongoDB',    FALSE, 2),

    ('Data Analyst Trainee', 'Excel',      TRUE,  2),
    ('Data Analyst Trainee', 'SQL',        TRUE,  2),
    ('Data Analyst Trainee', 'Statistics', FALSE, 1),

    ('Analytics Intern', 'Excel',              TRUE,  2),
    ('Analytics Intern', 'Python',             FALSE, 1),
    ('Analytics Intern', 'Data Visualization', FALSE, 1),

    ('Product Analyst', 'SQL',           TRUE, 2),
    ('Product Analyst', 'Excel',         TRUE, 2),
    ('Product Analyst', 'Communication', TRUE, 2)
) AS v(jtitle, sname, mand, lvl)
JOIN job j   ON j.title = v.jtitle
JOIN skill s ON s.skill_name = v.sname;

COMMIT;