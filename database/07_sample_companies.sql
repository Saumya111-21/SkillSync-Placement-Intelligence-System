-- SkillSync SAMPLE DATA, part 2: accounts, companies and recruiters
-- ALL DATA IN THE SAMPLE FILES IS SYNTHETIC (invented). The company and
-- person names are made up. The password_hash is a placeholder, not a hash:
-- nobody can log in with these accounts.

BEGIN;

INSERT INTO user_account (email, password_hash, role) VALUES
    ('admin@example.org',         'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'admin'),
    ('meera.kapoor@example.org',  'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'recruiter'),
    ('arjun.rao@example.org',     'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'recruiter'),
    ('sana.iyer@example.org',     'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'recruiter'),
    ('vikram.singh@example.org',  'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'recruiter'),
    ('neha.joshi@example.org',    'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'recruiter'),
    ('rohan.das@example.org',     'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'recruiter'),
    ('isha.verma@example.org',    'SAMPLE-PLACEHOLDER-NOT-A-HASH', 'recruiter');

-- Five approved companies, reviewed by the admin.
INSERT INTO company (company_name, industry, website, status_id, reviewed_by, reviewed_at)
SELECT v.cname, v.ind, v.site, 2, a.user_id, now()
FROM (VALUES
    ('Nimbus Analytics',        'Analytics',     'https://nimbus-analytics.example.org'),
    ('BrightPath Software',     'IT Services',   'https://brightpath-software.example.org'),
    ('DataHarbor Technologies', 'Analytics',     'https://dataharbor.example.org'),
    ('CloudNest Systems',       'Cloud Services','https://cloudnest.example.org'),
    ('PixelForge Studios',      'Web Development','https://pixelforge.example.org')
) AS v(cname, ind, site), user_account a
WHERE a.email = 'admin@example.org';

-- One company that is still pending review (status 1, no reviewer).
INSERT INTO company (company_name, industry, website)
VALUES ('Orbit Labs', 'Startup', 'https://orbit-labs.example.org');

INSERT INTO recruiter (user_id, company_id, full_name, designation)
SELECT u.user_id, c.company_id, v.fname, v.desig
FROM (VALUES
    ('meera.kapoor@example.org', 'Nimbus Analytics',        'Meera Kapoor', 'HR Manager'),
    ('arjun.rao@example.org',    'Nimbus Analytics',        'Arjun Rao',    'Talent Acquisition Lead'),
    ('sana.iyer@example.org',    'BrightPath Software',     'Sana Iyer',    'Recruitment Manager'),
    ('vikram.singh@example.org', 'DataHarbor Technologies', 'Vikram Singh', 'HR Business Partner'),
    ('neha.joshi@example.org',   'CloudNest Systems',       'Neha Joshi',   'Talent Partner'),
    ('rohan.das@example.org',    'PixelForge Studios',      'Rohan Das',    'HR Executive'),
    ('isha.verma@example.org',   'Orbit Labs',              'Isha Verma',   'Founder')
) AS v(email, cname, fname, desig)
JOIN user_account u ON u.email = v.email
JOIN company c      ON c.company_name = v.cname;

COMMIT;