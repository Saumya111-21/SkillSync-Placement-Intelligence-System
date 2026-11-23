"""Student skills: the level a student declares, and the evidence behind it.

A declared level is only a claim. list_my_skills always shows what supports it:
projects, certifications and the latest assessment (from the evidence view).
"""

import psycopg.errors

from .. import auth, database, validation
from . import current_student_id

MAX_ID = 2_147_483_647


def list_skills() -> list:
    """All skills with their category. Public: the forms need it."""
    return database.fetch_all(
        "SELECT k.skill_id, k.skill_name, c.category_name "
        "FROM skill k JOIN skill_category c ON c.category_id = k.category_id "
        "ORDER BY c.category_name, k.skill_name"
    )


def list_levels() -> list:
    """The four proficiency levels with their assessment score ranges."""
    return database.fetch_all(
        "SELECT level_id, level_name, min_score, max_score "
        "FROM proficiency_level ORDER BY level_id"
    )


def list_my_skills(user) -> list:
    """The student's skills with their evidence. Includes skills that have
    evidence (project, certification, assessment) but were never declared."""
    student_id = current_student_id(user)
    rows = database.fetch_all(
        "SELECT k.skill_id, k.skill_name, c.category_name, "
        "       e.declared_level_id, dl.level_name AS declared_level_name, "
        "       e.project_count, e.certification_count, "
        "       e.latest_assessed_level_id, al.level_name AS latest_assessed_level_name, "
        "       e.strongest_evidence "
        "FROM v_student_skill_evidence e "
        "JOIN skill k ON k.skill_id = e.skill_id "
        "JOIN skill_category c ON c.category_id = k.category_id "
        "LEFT JOIN proficiency_level dl ON dl.level_id = e.declared_level_id "
        "LEFT JOIN proficiency_level al ON al.level_id = e.latest_assessed_level_id "
        "WHERE e.student_id = %s "
        "ORDER BY k.skill_name",
        (student_id,),
    )
    return [dict(row) for row in rows]


def set_skill(user, skill_id, level_id) -> None:
    """Declare a skill at a level (1 to 4), or change the level if already declared."""
    student_id = current_student_id(user)
    skill_id = validation.clean_int(skill_id, "Skill", 1, MAX_ID)
    level_id = validation.clean_int(level_id, "Level", 1, 4)
    try:
        database.execute(
            "INSERT INTO student_skill (student_id, skill_id, declared_level_id) "
            "VALUES (%s, %s, %s) "
            "ON CONFLICT (student_id, skill_id) DO UPDATE "
            "SET declared_level_id = EXCLUDED.declared_level_id, updated_at = now()",
            (student_id, skill_id, level_id),
        )
    except psycopg.errors.ForeignKeyViolation as exc:
        if exc.diag.constraint_name == "student_skill_skill_id_fkey":
            raise validation.ValidationError("The selected skill does not exist.") from None
        raise auth.AuthError(auth.SESSION_ENDED) from None


def remove_skill(user, skill_id) -> None:
    """Remove the declaration. Projects, certifications and assessments stay,
    so the skill is still listed as evidence-only if any exists."""
    student_id = current_student_id(user)
    skill_id = validation.clean_int(skill_id, "Skill", 1, MAX_ID)
    removed = database.execute(
        "DELETE FROM student_skill WHERE student_id = %s AND skill_id = %s",
        (student_id, skill_id),
    )
    if removed == 0:
        raise validation.ValidationError("This skill is not in your profile.")