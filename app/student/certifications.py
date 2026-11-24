"""Student certifications.

A certification is one kind of evidence for the skills it covers. It supports a
skill and does not prove a level. Students choose from the master list of
certifications. They cannot create new ones: the placement office manages that
list and the skills each certification covers.
"""

from datetime import date

import psycopg.errors

from .. import auth, database, validation
from . import current_student_id

MAX_ID = 2_147_483_647
NOT_FOUND = "This certification is not in your profile."


def list_certifications() -> list:
    """All certifications a student can choose, with the skills each one covers."""
    rows = database.fetch_all(
        "SELECT c.certification_id, c.certification_name, c.issuing_body, "
        "       COALESCE(array_agg(k.skill_name ORDER BY k.skill_name) "
        "                FILTER (WHERE k.skill_id IS NOT NULL), ARRAY[]::varchar[]) AS skill_names "
        "FROM certification c "
        "LEFT JOIN certification_skill cs ON cs.certification_id = c.certification_id "
        "LEFT JOIN skill k ON k.skill_id = cs.skill_id "
        "GROUP BY c.certification_id "
        "ORDER BY c.certification_name"
    )
    return [dict(row) for row in rows]


def list_my_certifications(user) -> list:
    """The student's own certifications with the skills each one covers."""
    student_id = current_student_id(user)
    rows = database.fetch_all(
        "SELECT c.certification_id, c.certification_name, c.issuing_body, "
        "       sc.issue_date, sc.credential_id, sc.credential_url, "
        "       COALESCE(array_agg(k.skill_name ORDER BY k.skill_name) "
        "                FILTER (WHERE k.skill_id IS NOT NULL), ARRAY[]::varchar[]) AS skill_names "
        "FROM student_certification sc "
        "JOIN certification c ON c.certification_id = sc.certification_id "
        "LEFT JOIN certification_skill cs ON cs.certification_id = c.certification_id "
        "LEFT JOIN skill k ON k.skill_id = cs.skill_id "
        "WHERE sc.student_id = %s "
        "GROUP BY sc.student_id, sc.certification_id, c.certification_id "
        "ORDER BY c.certification_name",
        (student_id,),
    )
    return [dict(row) for row in rows]


def add_certification(user, certification_id, issue_date,
                      credential_id=None, credential_url=None) -> None:
    """Add a certification from the master list to the student's profile."""
    student_id = current_student_id(user)
    certification_id = validation.clean_int(certification_id, "Certification", 1, MAX_ID)
    issued = validation.clean_date(issue_date, "Issue date")
    if issued > date.today():
        raise validation.ValidationError("Issue date cannot be in the future.")
    credential_id = validation.clean_text(
        credential_id, "Credential ID", 100, required=False)
    credential_url = validation.clean_url(credential_url, "Credential link")
    try:
        database.execute(
            "INSERT INTO student_certification "
            "(student_id, certification_id, issue_date, credential_id, credential_url) "
            "VALUES (%s, %s, %s, %s, %s)",
            (student_id, certification_id, issued, credential_id, credential_url),
        )
    except psycopg.errors.UniqueViolation:
        raise validation.ValidationError(
            "This certification is already in your profile.") from None
    except psycopg.errors.CheckViolation:
        raise validation.ValidationError("Issue date cannot be in the future.") from None
    except psycopg.errors.ForeignKeyViolation as exc:
        if exc.diag.constraint_name == "student_certification_certification_id_fkey":
            raise validation.ValidationError(
                "The selected certification does not exist.") from None
        raise auth.AuthError(auth.SESSION_ENDED) from None


def remove_certification(user, certification_id) -> None:
    """Remove a certification from the student's own profile."""
    student_id = current_student_id(user)
    certification_id = validation.clean_int(certification_id, "Certification", 1, MAX_ID)
    removed = database.execute(
        "DELETE FROM student_certification "
        "WHERE student_id = %s AND certification_id = %s",
        (student_id, certification_id),
    )
    if removed == 0:
        raise validation.ValidationError(NOT_FOUND)