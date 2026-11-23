"""Login, registration and role checks for SkillSync.

Rules:
- Every login failure gives the same message, so nobody can find out which
  emails are registered.
- A registration creates the account and its profile in ONE transaction:
  either both exist or neither does.
- Admin accounts cannot be created here. The placement office creates them
  directly in the database.
- Passwords are hashed by app.security and never stored, logged or returned.
"""

import psycopg.errors

from . import database, security, validation


class AuthError(Exception):
    """Login or registration failed. The message is safe to show to the user."""


class PermissionDenied(Exception):
    """The logged-in user is not allowed to do this."""


INVALID_LOGIN = "Invalid email or password."
SESSION_ENDED = "Your session has ended. Please log in again."
MAX_ID = 2_147_483_647

# Checked when the email is unknown, so an unknown email takes about as long
# as a wrong password and the time does not reveal which emails exist.
_DUMMY_HASH = security.hash_password("Dummy-Password-0")

_DUPLICATE_MESSAGES = {
    "user_account_email_key": "This email is already registered.",
    "student_enrollment_no_key": "This enrollment number is already registered.",
}

_FOREIGN_KEY_MESSAGES = {
    "student_course_id_fkey": "The selected course does not exist.",
    "recruiter_company_id_fkey": "The selected company does not exist.",
}


def _load_profile(user_id, role) -> dict:
    """The profile ids and name that belong to an account."""
    if role == "student":
        row = database.fetch_one(
            "SELECT student_id, full_name FROM student WHERE user_id = %s",
            (user_id,),
        )
    elif role == "recruiter":
        row = database.fetch_one(
            "SELECT r.recruiter_id, r.company_id, r.full_name, c.company_name "
            "FROM recruiter r JOIN company c ON c.company_id = r.company_id "
            "WHERE r.user_id = %s",
            (user_id,),
        )
    else:
        row = None
    return dict(row) if row else {}


def _build_session(user_row) -> dict:
    """What the application keeps about a logged-in user. Never the password hash."""
    session = {
        "user_id": user_row["user_id"],
        "email": user_row["email"],
        "role": user_row["role"],
    }
    session.update(_load_profile(user_row["user_id"], user_row["role"]))
    return session


def login(email, password) -> dict:
    """Return the session for a valid login. Raises AuthError with one message for every failure."""
    try:
        email = validation.clean_email(email)
    except validation.ValidationError:
        raise AuthError(INVALID_LOGIN) from None

    row = database.fetch_one(
        "SELECT user_id, email, password_hash, role, is_active "
        "FROM user_account WHERE email = %s",
        (email,),
    )
    stored_hash = row["password_hash"] if row else _DUMMY_HASH
    password_ok = security.verify_password(password, stored_hash)

    if row is None or not password_ok or not row["is_active"]:
        raise AuthError(INVALID_LOGIN)
    return _build_session(row)


def refresh_session(session) -> dict:
    """Read the account again. Ends the session if it was deactivated or deleted."""
    if not session or "user_id" not in session:
        raise AuthError(SESSION_ENDED)
    row = database.fetch_one(
        "SELECT user_id, email, role, is_active FROM user_account WHERE user_id = %s",
        (session["user_id"],),
    )
    if row is None or not row["is_active"]:
        raise AuthError(SESSION_ENDED)
    return _build_session(row)


def _hash_new_password(password) -> str:
    """Hash a new password. A weak password becomes a ValidationError."""
    try:
        return security.hash_password(password)
    except ValueError as exc:
        raise validation.ValidationError(str(exc)) from None


def _registration_error(exc) -> AuthError:
    """Turn a database constraint error into a message the user can understand."""
    name = exc.diag.constraint_name
    if isinstance(exc, psycopg.errors.UniqueViolation):
        return AuthError(_DUPLICATE_MESSAGES.get(name, "This record already exists."))
    return AuthError(
        _FOREIGN_KEY_MESSAGES.get(name, "A related record does not exist.")
    )


def register_student(email, password, full_name, enrollment_no, course_id,
                     admission_year, phone=None) -> dict:
    """Create a student account and profile together, then log the student in."""
    email = validation.clean_email(email)
    full_name = validation.clean_text(full_name, "Full name", 150)
    enrollment_no = validation.clean_text(enrollment_no, "Enrollment number", 30)
    course_id = validation.clean_int(course_id, "Course", 1, MAX_ID)
    admission_year = validation.clean_int(admission_year, "Admission year", 2000, 2100)
    phone = validation.clean_phone(phone)
    password_hash = _hash_new_password(password)

    try:
        with database.transaction() as conn:
            user = conn.execute(
                "INSERT INTO user_account (email, password_hash, role) "
                "VALUES (%s, %s, 'student') RETURNING user_id",
                (email, password_hash),
            ).fetchone()
            conn.execute(
                "INSERT INTO student (user_id, course_id, enrollment_no, "
                "full_name, phone, admission_year) VALUES (%s, %s, %s, %s, %s, %s)",
                (user["user_id"], course_id, enrollment_no, full_name, phone,
                 admission_year),
            )
    except (psycopg.errors.UniqueViolation, psycopg.errors.ForeignKeyViolation) as exc:
        raise _registration_error(exc) from None
    return login(email, password)


def register_recruiter(email, password, full_name, designation, company_id) -> dict:
    """Create a recruiter account and profile together, then log the recruiter in."""
    email = validation.clean_email(email)
    full_name = validation.clean_text(full_name, "Full name", 150)
    designation = validation.clean_text(designation, "Designation", 100)
    company_id = validation.clean_int(company_id, "Company", 1, MAX_ID)
    password_hash = _hash_new_password(password)

    try:
        with database.transaction() as conn:
            user = conn.execute(
                "INSERT INTO user_account (email, password_hash, role) "
                "VALUES (%s, %s, 'recruiter') RETURNING user_id",
                (email, password_hash),
            ).fetchone()
            conn.execute(
                "INSERT INTO recruiter (user_id, company_id, full_name, designation) "
                "VALUES (%s, %s, %s, %s)",
                (user["user_id"], company_id, full_name, designation),
            )
    except (psycopg.errors.UniqueViolation, psycopg.errors.ForeignKeyViolation) as exc:
        raise _registration_error(exc) from None
    return login(email, password)


def change_password(user_id, old_password, new_password) -> None:
    """Change a password after checking the old one."""
    row = database.fetch_one(
        "SELECT password_hash, is_active FROM user_account WHERE user_id = %s",
        (user_id,),
    )
    if (row is None or not row["is_active"]
            or not security.verify_password(old_password, row["password_hash"])):
        raise AuthError("The current password is not correct.")
    new_hash = _hash_new_password(new_password)
    database.execute(
        "UPDATE user_account SET password_hash = %s WHERE user_id = %s",
        (new_hash, user_id),
    )


def require_role(user, *roles) -> dict:
    """Call this first in every protected function. Raises PermissionDenied."""
    if not user or user.get("role") not in roles:
        raise PermissionDenied("You are not allowed to do this.")
    return user