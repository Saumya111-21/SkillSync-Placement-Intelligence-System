-- SkillSync lookup data: fixed rows that the rules depend on
-- Source: docs/relational_schema.md

BEGIN;

-- Score ranges together cover every whole score from 0 to 100, with no gap and no overlap.
INSERT INTO proficiency_level (level_id, level_name, min_score, max_score) VALUES
    (1, 'Beginner',      0,  39),
    (2, 'Intermediate', 40,  64),
    (3, 'Advanced',     65,  84),
    (4, 'Expert',       85, 100);

INSERT INTO review_status (status_id, status_name) VALUES
    (1, 'pending'),
    (2, 'approved'),
    (3, 'rejected');

INSERT INTO application_stage (stage_id, stage_name, stage_order) VALUES
    (1, 'applied',     1),
    (2, 'shortlisted', 2),
    (3, 'interview',   3),
    (4, 'offered',     4),
    (5, 'rejected',    5),
    (6, 'withdrawn',   6);

INSERT INTO skill_category (category_name) VALUES
    ('Programming'),
    ('Database'),
    ('Data Analysis'),
    ('Visualization'),
    ('Web Development'),
    ('Cloud and DevOps'),
    ('Tools'),
    ('Soft Skill');

-- First matching configuration. The preferred weight is 1 - 0.70 = 0.30.
INSERT INTO match_config (version_label, mandatory_weight, description) VALUES
    ('v1', 0.70,
     'Overall score = 0.70 x mandatory coverage + 0.30 x preferred coverage. '
     'Coverage = percentage of required skills whose required level is met. '
     'A skill-coverage indicator, not a hiring probability.');

COMMIT;