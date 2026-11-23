"""Student projects and the skills each project used.

A project is one kind of evidence for a skill. Creating or changing a project
and its skill links happens in ONE transaction. Ownership is checked inside the
SQL (WHERE student_id = ...), so a student cannot reach another student's project.
"""

import psycopg.errors

from .. import auth, database, validation
from . import current_student_id

MAX_ID = 2_147_483_647
MAX_SKILLS_PER_PROJECT = 15
NOT_FOUND = "Project not found."


def _clean_skill_ids(skill_ids) -> list:
    """A sorted list of distinct, valid skill ids."""
    if skill_ids is None:
        return []
    if not isinstance(skill_ids, (list, tuple, set)):
        raise validation.ValidationError("Skills must be a list.")
    cleaned = sorted({validation.clean_int(s, "Skill", 1, MAX_ID) for s in skill_ids})
    if len(cleaned) > MAX_SKILLS_PER_PROJECT:
        raise validation.ValidationError(
            f"A project can have at most {MAX_SKILLS_PER_PROJECT} skills."
        )
    return cleaned


def _optional_date(value, label):
    """An empty value gives None, anything else must be a valid date."""
    if value is None or (isinstance(value, str) and not value.strip()):
        return None
    return validation.clean_date(value, label)


def _clean_fields(title, description, start_date, end_date, project_url) -> tuple:
    title = validation.clean_text(title, "Title", 200)
    if isinstance(description, str):
        description = " ".join(description.split())      # line breaks become spaces
    description = validation.clean_text(description, "Description", 2000)
    start = validation.clean_date(start_date, "Start date")
    end = _optional_date(end_date, "End date")
    if end is not None and end < start:
        raise validation.ValidationError("End date cannot be before the start date.")
    url = validation.clean_url(project_url, "Project link")
    return title, description, start, end, url


def _save_skills(conn, project_id, skill_ids) -> None:
    if skill_ids:
        conn.execute(
            "INSERT INTO project_skill (project_id, skill_id) "
            "SELECT %s::int, unnest(%s::int[])",
            (project_id, skill_ids),
        )


def _skill_error(exc) -> Exception:
    if exc.diag.constraint_name == "project_skill_skill_id_fkey":
        return validation.ValidationError("One of the selected skills does not exist.")
    return auth.AuthError(auth.SESSION_ENDED)


def list_my_projects(user) -> list:
    """The student's projects, newest first, each with its skills."""
    student_id = current_student_id(user)
    rows = database.fetch_all(
        "SELECT p.project_id, p.title, p.description, p.start_date, p.end_date, "
        "       p.project_url, "
        "       COALESCE(array_agg(k.skill_id ORDER BY k.skill_name) "
        "                FILTER (WHERE k.skill_id IS NOT NULL), ARRAY[]::int[]) AS skill_ids, "
        "       COALESCE(array_agg(k.skill_name ORDER BY k.skill_name) "
        "                FILTER (WHERE k.skill_id IS NOT NULL), ARRAY[]::varchar[]) AS skill_names "
        "FROM student_project p "
        "LEFT JOIN project_skill ps ON ps.project_id = p.project_id "
        "LEFT JOIN skill k ON k.skill_id = ps.skill_id "
        "WHERE p.student_id = %s "
        "GROUP BY p.project_id "
        "ORDER BY p.start_date DESC, p.project_id DESC",
        (student_id,),
    )
    return [dict(row) for row in rows]


def add_project(user, title, description, start_date, end_date=None,
                project_url=None, skill_ids=None) -> int:
    """Create a project with its skills. Returns the new project id."""
    student_id = current_student_id(user)
    fields = _clean_fields(title, description, start_date, end_date, project_url)
    ids = _clean_skill_ids(skill_ids)
    try:
        with database.transaction() as conn:
            project_id = conn.execute(
                "INSERT INTO student_project (student_id, title, description, "
                "start_date, end_date, project_url) "
                "VALUES (%s, %s, %s, %s, %s, %s) RETURNING project_id",
                (student_id, *fields),
            ).fetchone()["project_id"]
            _save_skills(conn, project_id, ids)
    except psycopg.errors.ForeignKeyViolation as exc:
        raise _skill_error(exc) from None
    return project_id


def update_project(user, project_id, title, description, start_date, end_date=None,
                   project_url=None, skill_ids=None) -> None:
    """Change a project and replace its skills. Only the owner can do this."""
    student_id = current_student_id(user)
    project_id = validation.clean_int(project_id, "Project", 1, MAX_ID)
    fields = _clean_fields(title, description, start_date, end_date, project_url)
    ids = _clean_skill_ids(skill_ids)
    try:
        with database.transaction() as conn:
            changed = conn.execute(
                "UPDATE student_project SET title = %s, description = %s, "
                "start_date = %s, end_date = %s, project_url = %s "
                "WHERE project_id = %s AND student_id = %s",
                (*fields, project_id, student_id),
            ).rowcount
            if changed == 0:
                raise validation.ValidationError(NOT_FOUND)
            conn.execute("DELETE FROM project_skill WHERE project_id = %s", (project_id,))
            _save_skills(conn, project_id, ids)
    except psycopg.errors.ForeignKeyViolation as exc:
        raise _skill_error(exc) from None


def delete_project(user, project_id) -> None:
    """Delete a project and its skill links. Only the owner can do this."""
    student_id = current_student_id(user)
    project_id = validation.clean_int(project_id, "Project", 1, MAX_ID)
    removed = database.execute(
        "DELETE FROM student_project WHERE project_id = %s AND student_id = %s",
        (project_id, student_id),
    )
    if removed == 0:
        raise validation.ValidationError(NOT_FOUND)