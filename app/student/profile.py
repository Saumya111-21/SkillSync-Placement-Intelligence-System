"""Student profile: read and update. A student can only reach their own profile."""

import psycopg.errors

from .. import auth, database, validation
from . import current_student_id

MAX_ID = 2_147_483_647


def list_courses() -> list:
    """All courses with their department. Public: the registration form needs it."""
    return database.fetch_all(
        "SELECT c.course_id, c.course_name, c.duration_years, d.department_name "
        "FROM course c JOIN department d ON d.department_id = c.department_id "
        "ORDER BY d.department_name, c.course_name"
    )


def get_profile(user) -> dict:
    """The logged-in student's own profile, with course, department and CGPA."""
    student_id = current_student_id(user)
    row = database.fetch_one(
        "SELECT s.student_id, u.email, s.full_name, s.phone, s.enrollment_no, "
        "       s.admission_year, c.course_id, c.course_name, c.duration_years, "
        "       d.department_name, g.cgpa, g.semesters_recorded "
        "FROM student s "
        "JOIN user_account u ON u.user_id = s.user_id "
        "JOIN course c ON c.course_id = s.course_id "
        "JOIN department d ON d.department_id = c.department_id "
        "LEFT JOIN v_student_cgpa g ON g.student_id = s.student_id "
        "WHERE s.student_id = %s",
        (student_id,),
    )
    if row is None:
        raise auth.AuthError(auth.SESSION_ENDED)
    return dict(row)


def update_profile(user, full_name, phone, course_id) -> dict:
    """Change name, phone and course. Email, enrollment number and admission
    year are identity data and are changed only by the placement office."""
    student_id = current_student_id(user)
    full_name = validation.clean_text(full_name, "Full name", 150)
    phone = validation.clean_phone(phone)
    course_id = validation.clean_int(course_id, "Course", 1, MAX_ID)
    try:
        changed = database.execute(
            "UPDATE student SET full_name = %s, phone = %s, course_id = %s "
            "WHERE student_id = %s",
            (full_name, phone, course_id, student_id),
        )
    except psycopg.errors.ForeignKeyViolation:
        raise validation.ValidationError("The selected course does not exist.") from None
    if changed == 0:
        raise auth.AuthError(auth.SESSION_ENDED)
    return get_profile(user)