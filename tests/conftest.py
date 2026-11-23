"""Shared test helpers. pytest loads this file by itself.

make_student creates throwaway students whose emails end in
@pytest.example.test. Every such account is deleted before and after each test
that uses the helper, so the sample data is left unchanged. Deleting a student
also deletes their skills, projects, certifications and assessments (cascade).
"""

import pytest

from app import auth, database

DOMAIN = "@pytest.example.test"
GOOD_PASSWORD = "Correct-Horse-9"


def remove_test_accounts():
    pattern = "%" + DOMAIN
    with database.transaction() as conn:
        conn.execute(
            "DELETE FROM student WHERE user_id IN "
            "(SELECT user_id FROM user_account WHERE email LIKE %s)", (pattern,))
        conn.execute(
            "DELETE FROM recruiter WHERE user_id IN "
            "(SELECT user_id FROM user_account WHERE email LIKE %s)", (pattern,))
        conn.execute("DELETE FROM user_account WHERE email LIKE %s", (pattern,))


@pytest.fixture
def make_student():
    """Return a function that registers a throwaway student and returns the session."""
    remove_test_accounts()

    def _make(name, **overrides):
        course_id = database.fetch_one(
            "SELECT course_id FROM course ORDER BY course_id LIMIT 1")["course_id"]
        arguments = {
            "email": f"{name}{DOMAIN}",
            "password": GOOD_PASSWORD,
            "full_name": "Test Student",
            "enrollment_no": f"PYT-{name}",
            "course_id": course_id,
            "admission_year": 2024,
        }
        arguments.update(overrides)
        return auth.register_student(**arguments)

    yield _make
    remove_test_accounts()