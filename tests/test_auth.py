"""Tests for app/auth.py. They use the real skillsync database.

Every test account has an email ending in @pytest.example.test. A cleanup step
deletes all such accounts before and after each test, so the sample data is left
unchanged. Identity numbers are still used up, which is normal.
"""

import pytest

from app import auth, database, validation

DOMAIN = "@pytest.example.test"
GOOD_PASSWORD = "Correct-Horse-9"


def _remove_test_accounts():
    pattern = "%" + DOMAIN
    with database.transaction() as conn:
        conn.execute(
            "DELETE FROM student WHERE user_id IN "
            "(SELECT user_id FROM user_account WHERE email LIKE %s)", (pattern,))
        conn.execute(
            "DELETE FROM recruiter WHERE user_id IN "
            "(SELECT user_id FROM user_account WHERE email LIKE %s)", (pattern,))
        conn.execute("DELETE FROM user_account WHERE email LIKE %s", (pattern,))


@pytest.fixture(autouse=True)
def clean_test_accounts():
    _remove_test_accounts()
    yield
    _remove_test_accounts()


def _course_id():
    return database.fetch_one(
        "SELECT course_id FROM course ORDER BY course_id LIMIT 1")["course_id"]


def _company_id():
    return database.fetch_one(
        "SELECT company_id FROM company WHERE company_name = 'Nimbus Analytics'"
    )["company_id"]


def _email(name):
    return f"{name}{DOMAIN}"


def _new_student(name, **overrides):
    arguments = {
        "email": _email(name),
        "password": GOOD_PASSWORD,
        "full_name": "Test Student",
        "enrollment_no": f"PYT-{name}",
        "course_id": _course_id(),
        "admission_year": 2024,
    }
    arguments.update(overrides)
    return auth.register_student(**arguments)


def _account_count(email):
    return database.fetch_one(
        "SELECT count(*) AS n FROM user_account WHERE email = %s", (email,))["n"]


def test_student_registration_and_login():
    session = _new_student("t1")
    assert session["role"] == "student"
    assert session["email"] == _email("t1")
    assert "student_id" in session
    assert "password_hash" not in session
    assert GOOD_PASSWORD not in str(session)
    again = auth.login(_email("t1").upper(), GOOD_PASSWORD)   # email is case-insensitive
    assert again["user_id"] == session["user_id"]


def test_password_is_stored_as_a_hash():
    _new_student("t2")
    row = database.fetch_one(
        "SELECT password_hash FROM user_account WHERE email = %s", (_email("t2"),))
    assert row["password_hash"] != GOOD_PASSWORD
    assert row["password_hash"].startswith("$argon2id$")


def test_every_login_failure_gives_the_same_message():
    _new_student("t3")
    attempts = [
        (_email("t3"), "Wrong-Password-1"),        # wrong password
        (_email("nobody"), GOOD_PASSWORD),         # unknown email
        ("not-an-email", GOOD_PASSWORD),           # badly written email
        (_email("t3"), None),                      # no password at all
    ]
    for email, password in attempts:
        with pytest.raises(auth.AuthError) as error:
            auth.login(email, password)
        assert str(error.value) == auth.INVALID_LOGIN


def test_deactivated_account_cannot_log_in():
    session = _new_student("t4")
    database.execute(
        "UPDATE user_account SET is_active = FALSE WHERE user_id = %s",
        (session["user_id"],))
    with pytest.raises(auth.AuthError) as error:
        auth.login(_email("t4"), GOOD_PASSWORD)
    assert str(error.value) == auth.INVALID_LOGIN
    with pytest.raises(auth.AuthError):
        auth.refresh_session(session)           # an open session ends too


def test_refresh_session_returns_current_data():
    session = _new_student("t5")
    refreshed = auth.refresh_session(session)
    assert refreshed["user_id"] == session["user_id"]
    assert refreshed["role"] == "student"
    for broken in (None, {}, {"role": "admin"}):
        with pytest.raises(auth.AuthError):
            auth.refresh_session(broken)


def test_duplicate_email_is_refused():
    _new_student("t6")
    with pytest.raises(auth.AuthError) as error:
        _new_student("t6", enrollment_no="PYT-other")
    assert "email" in str(error.value).lower()
    assert _account_count(_email("t6")) == 1


def test_duplicate_enrollment_number_leaves_no_half_created_account():
    _new_student("t7a", enrollment_no="PYT-dup")
    with pytest.raises(auth.AuthError) as error:
        _new_student("t7b", enrollment_no="PYT-dup")
    assert "enrollment" in str(error.value).lower()
    assert _account_count(_email("t7b")) == 0   # the whole registration was undone


def test_unknown_course_is_refused_and_leaves_nothing():
    with pytest.raises(auth.AuthError) as error:
        _new_student("t8", course_id=999999)
    assert "course" in str(error.value).lower()
    assert _account_count(_email("t8")) == 0


def test_weak_password_and_bad_input_are_refused_before_the_database():
    bad_inputs = [
        {"password": "short1"},            # weak password
        {"email": "bad"},                  # bad email
        {"admission_year": 1999},          # out of range
        {"phone": "123"},                  # bad phone
        {"full_name": "   "},              # empty name
    ]
    for overrides in bad_inputs:
        with pytest.raises(validation.ValidationError):
            _new_student("t9", **overrides)
    assert _account_count(_email("t9")) == 0


def test_recruiter_registration_and_login():
    session = auth.register_recruiter(
        _email("t10"), GOOD_PASSWORD, "Test Recruiter", "HR Manager", _company_id())
    assert session["role"] == "recruiter"
    assert session["company_name"] == "Nimbus Analytics"
    assert "recruiter_id" in session
    assert auth.login(_email("t10"), GOOD_PASSWORD)["user_id"] == session["user_id"]


def test_change_password():
    session = _new_student("t11")
    with pytest.raises(auth.AuthError):                       # wrong current password
        auth.change_password(session["user_id"], "Wrong-Password-1", "New-Horse-Battery-7")
    with pytest.raises(validation.ValidationError):           # weak new password
        auth.change_password(session["user_id"], GOOD_PASSWORD, "weak")
    auth.change_password(session["user_id"], GOOD_PASSWORD, "New-Horse-Battery-7")
    assert auth.login(_email("t11"), "New-Horse-Battery-7")["user_id"] == session["user_id"]
    with pytest.raises(auth.AuthError):                       # the old password is dead
        auth.login(_email("t11"), GOOD_PASSWORD)


def test_require_role():
    admin = {"role": "admin"}
    assert auth.require_role(admin, "admin", "recruiter") is admin
    for user in ({"role": "student"}, {}, None):
        with pytest.raises(auth.PermissionDenied):
            auth.require_role(user, "admin", "recruiter")
            