"""Tests for app/student/skills.py. They use the real skillsync database.

Throwaway students come from the make_student helper in conftest.py and are
deleted afterwards (with their skills, assessments and certifications).
"""

import pytest

from app import auth, database, validation
from app.student import skills


def _skill_id(name):
    return database.fetch_one(
        "SELECT skill_id FROM skill WHERE skill_name = %s", (name,))["skill_id"]


def _declaration_count(student_id):
    return database.fetch_one(
        "SELECT count(*) AS n FROM student_skill WHERE student_id = %s",
        (student_id,))["n"]


def _by_name(session):
    return {row["skill_name"]: row for row in skills.list_my_skills(session)}


def test_public_lists_are_complete():
    all_skills = skills.list_skills()
    assert len(all_skills) == 30
    assert "Python" in {row["skill_name"] for row in all_skills}
    levels = skills.list_levels()
    assert [row["level_name"] for row in levels] == [
        "Beginner", "Intermediate", "Advanced", "Expert"]


def test_new_student_has_no_skills(make_student):
    session = make_student("s2")
    assert skills.list_my_skills(session) == []


def test_set_skill_adds_a_declaration(make_student):
    session = make_student("s3")
    skills.set_skill(session, _skill_id("Python"), 3)
    rows = skills.list_my_skills(session)
    assert len(rows) == 1
    row = rows[0]
    assert row["skill_name"] == "Python"
    assert row["declared_level_id"] == 3
    assert row["declared_level_name"] == "Advanced"
    assert row["project_count"] == 0
    assert row["certification_count"] == 0
    assert row["latest_assessed_level_id"] is None
    assert row["strongest_evidence"] == "declared only"     # a claim, not proof


def test_setting_again_changes_the_level_without_a_duplicate(make_student):
    session = make_student("s4")
    python = _skill_id("Python")
    skills.set_skill(session, python, 2)
    skills.set_skill(session, python, 4)
    assert _declaration_count(session["student_id"]) == 1
    assert _by_name(session)["Python"]["declared_level_id"] == 4


def test_bad_levels_and_unknown_skills_are_refused(make_student):
    session = make_student("s5")
    python = _skill_id("Python")
    for level in (0, 5, -1, "x", None, True, 2.5):
        with pytest.raises(validation.ValidationError):
            skills.set_skill(session, python, level)
    for skill in (999999, 0, "abc", None):
        with pytest.raises(validation.ValidationError):
            skills.set_skill(session, skill, 2)
    assert _declaration_count(session["student_id"]) == 0      # nothing was stored


def test_remove_skill(make_student):
    session = make_student("s6")
    python = _skill_id("Python")
    skills.set_skill(session, python, 3)
    skills.remove_skill(session, python)
    assert skills.list_my_skills(session) == []
    with pytest.raises(validation.ValidationError):             # nothing left to remove
        skills.remove_skill(session, python)


def test_removing_a_declaration_keeps_the_evidence(make_student):
    session = make_student("s7")
    python = _skill_id("Python")
    skills.set_skill(session, python, 2)
    database.execute(
        "INSERT INTO skill_assessment (student_id, skill_id, score_percent) "
        "VALUES (%s, %s, 70)", (session["student_id"], python))     # 70 = Advanced (level 3)
    row = _by_name(session)["Python"]
    assert row["declared_level_id"] == 2
    assert row["latest_assessed_level_id"] == 3
    assert row["strongest_evidence"] == "assessed"

    skills.remove_skill(session, python)
    row = _by_name(session)["Python"]                           # still listed
    assert row["declared_level_id"] is None
    assert row["declared_level_name"] is None
    assert row["latest_assessed_level_id"] == 3
    assert row["strongest_evidence"] == "assessed"


def test_evidence_without_a_declaration_is_listed(make_student):
    session = make_student("s8")
    certification_id = database.fetch_one(
        "SELECT certification_id FROM certification "
        "WHERE certification_name = 'Python for Everybody'")["certification_id"]
    database.execute(
        "INSERT INTO student_certification (student_id, certification_id, issue_date) "
        "VALUES (%s, %s, DATE '2025-01-01')", (session["student_id"], certification_id))
    rows = skills.list_my_skills(session)
    assert len(rows) == 1
    row = rows[0]
    assert row["skill_name"] == "Python"
    assert row["declared_level_id"] is None
    assert row["certification_count"] == 1
    assert row["project_count"] == 0
    assert row["strongest_evidence"] == "certification"        # supports, does not prove a level


def test_students_cannot_touch_each_others_skills(make_student):
    a = make_student("s9a")
    b = make_student("s9b")
    python = _skill_id("Python")
    skills.set_skill(a, python, 3)
    skills.set_skill(b, python, 1)
    assert _by_name(a)["Python"]["declared_level_id"] == 3      # b's change did not reach a
    skills.remove_skill(b, python)
    assert _by_name(a)["Python"]["declared_level_id"] == 3      # b's removal did not reach a
    assert skills.list_my_skills(b) == []
    with pytest.raises(validation.ValidationError):             # b cannot remove what b does not have
        skills.remove_skill(b, python)


def test_deleted_student_ends_the_session(make_student):
    session = make_student("s10")
    database.execute("DELETE FROM student WHERE student_id = %s", (session["student_id"],))
    with pytest.raises(auth.AuthError):
        skills.set_skill(session, _skill_id("Python"), 2)


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
            skills.list_my_skills(user)
        with pytest.raises(auth.PermissionDenied):
            skills.set_skill(user, 1, 1)
        with pytest.raises(auth.PermissionDenied):
            skills.remove_skill(user, 1)