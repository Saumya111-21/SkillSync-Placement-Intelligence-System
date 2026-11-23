"""Tests for app/student/profile.py. They use the real skillsync database."""

import pytest

from app import auth, database, validation
from app.student import profile


def test_course_list_is_public():
    courses = profile.list_courses()
    assert len(courses) == 6
    assert {"course_id", "course_name", "duration_years", "department_name"} <= set(courses[0])


def test_get_profile_returns_own_data(make_student):
    session = make_student("p1", full_name="Profile One")
    result = profile.get_profile(session)
    assert result["full_name"] == "Profile One"
    assert result["email"] == "p1@pytest.example.test"
    assert result["enrollment_no"] == "PYT-p1"
    assert result["cgpa"] is None                 # no grades yet
    assert result["department_name"]


def test_profile_shows_cgpa_for_a_student_with_grades():
    """Aarav Sharma (sample data): the CGPA worked out by hand is 8.17."""
    student_id = database.fetch_one(
        "SELECT student_id FROM student WHERE enrollment_no = 'CS23-001'")["student_id"]
    result = profile.get_profile({"role": "student", "student_id": student_id})
    assert str(result["cgpa"]) == "8.17"
    assert result["semesters_recorded"] == 6
    assert result["course_name"] == "B.Tech CSE"
    assert result["department_name"] == "Computer Science"


def test_update_profile_changes_only_allowed_fields(make_student):
    session = make_student("p4")
    before = profile.get_profile(session)
    other = [c for c in profile.list_courses() if c["course_id"] != before["course_id"]][0]
    after = profile.update_profile(session, "  New Name  ", "+91 98100-00001", other["course_id"])
    assert after["full_name"] == "New Name"
    assert after["phone"] == "+919810000001"
    assert after["course_id"] == other["course_id"]
    # identity data is not editable here
    assert after["email"] == before["email"]
    assert after["enrollment_no"] == before["enrollment_no"]
    assert after["admission_year"] == before["admission_year"]
    # an empty phone clears the field
    assert profile.update_profile(session, "New Name", "", other["course_id"])["phone"] is None


def test_update_profile_rejects_bad_input(make_student):
    session = make_student("p5")
    before = profile.get_profile(session)
    cid = before["course_id"]
    bad_inputs = [
        ("", "9810000001", cid),            # empty name
        ("a" * 151, None, cid),             # name too long
        ("Ok Name", "123", cid),            # bad phone
        ("Ok Name", None, 999999),          # course that does not exist
        ("Ok Name", None, "abc"),           # course that is not a number
    ]
    for name, phone, course in bad_inputs:
        with pytest.raises(validation.ValidationError):
            profile.update_profile(session, name, phone, course)
    assert profile.get_profile(session) == before      # nothing changed


def test_other_roles_and_broken_sessions_are_refused():
    broken = [
        None,
        {},
        {"role": "recruiter"},
        {"role": "admin"},
        {"role": "student"},                              # no student id
        {"role": "student", "student_id": True},          # not a real id
        {"role": "student", "student_id": "5"},           # text, not a number
    ]
    for user in broken:
        with pytest.raises(auth.PermissionDenied):
            profile.get_profile(user)
        with pytest.raises(auth.PermissionDenied):
            profile.update_profile(user, "Name", None, 1)


def test_update_changes_only_the_logged_in_student(make_student):
    a = make_student("p7a", full_name="Student A")
    b = make_student("p7b", full_name="Student B")
    profile.update_profile(a, "Changed A", None, profile.get_profile(a)["course_id"])
    assert profile.get_profile(a)["full_name"] == "Changed A"
    assert profile.get_profile(b)["full_name"] == "Student B"


def test_deleted_student_ends_the_session(make_student):
    session = make_student("p8")
    database.execute("DELETE FROM student WHERE student_id = %s", (session["student_id"],))
    with pytest.raises(auth.AuthError):
        profile.get_profile(session)
    with pytest.raises(auth.AuthError):
        profile.update_profile(session, "Name", None, 1)