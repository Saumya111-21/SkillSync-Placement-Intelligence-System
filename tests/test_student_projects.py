"""Tests for app/student/projects.py. They use the real skillsync database.

Throwaway students come from the make_student helper in conftest.py and are
deleted afterwards (with their projects and project skills).
"""

from datetime import date

import pytest

from app import auth, database, validation
from app.student import projects, skills


def _skill_id(name):
    return database.fetch_one(
        "SELECT skill_id FROM skill WHERE skill_name = %s", (name,))["skill_id"]


def _add(session, **overrides):
    arguments = {
        "title": "Test Project",
        "description": "A test project.",
        "start_date": "2026-01-10",
    }
    arguments.update(overrides)
    return projects.add_project(session, **arguments)


def test_new_student_has_no_projects(make_student):
    assert projects.list_my_projects(make_student("j1")) == []


def test_add_project_with_skills(make_student):
    session = make_student("j2")
    python, sql = _skill_id("Python"), _skill_id("SQL")
    project_id = _add(session, end_date="2026-03-01",
                      project_url="https://example.org/p", skill_ids=[sql, python])
    rows = projects.list_my_projects(session)
    assert len(rows) == 1
    row = rows[0]
    assert row["project_id"] == project_id
    assert row["title"] == "Test Project"
    assert row["start_date"] == date(2026, 1, 10)
    assert row["end_date"] == date(2026, 3, 1)
    assert row["project_url"] == "https://example.org/p"
    assert row["skill_names"] == ["Python", "SQL"]         # sorted by skill name
    assert row["skill_ids"] == [python, sql]


def test_description_line_breaks_become_spaces(make_student):
    session = make_student("j3")
    _add(session, description="line one\nline two\r\n  line three")
    assert projects.list_my_projects(session)[0]["description"] == "line one line two line three"


def test_project_without_skills(make_student):
    session = make_student("j4")
    _add(session)                                           # skill_ids not given
    _add(session, title="Second", skill_ids=[])             # empty list
    for row in projects.list_my_projects(session):
        assert row["skill_ids"] == []
        assert row["skill_names"] == []
        assert row["end_date"] is None
        assert row["project_url"] is None


def test_bad_input_is_refused_and_nothing_is_stored(make_student):
    session = make_student("j5")
    bad_inputs = [
        {"title": ""},
        {"title": "a" * 201},
        {"description": ""},
        {"description": "a" * 2001},
        {"start_date": "not a date"},
        {"start_date": None},
        {"end_date": "2025-12-31"},                         # before the start date
        {"end_date": "31-12-2026"},                         # wrong date form
        {"project_url": "ftp://example.org"},
        {"skill_ids": "Python"},                            # not a list
        {"skill_ids": list(range(1, 17))},                  # 16 skills, the limit is 15
        {"skill_ids": [0]},
        {"skill_ids": ["abc"]},
    ]
    for overrides in bad_inputs:
        with pytest.raises(validation.ValidationError):
            _add(session, **overrides)
    assert projects.list_my_projects(session) == []


def test_unknown_skill_creates_no_project(make_student):
    session = make_student("j6")
    with pytest.raises(validation.ValidationError) as error:
        _add(session, skill_ids=[_skill_id("Python"), 999999])
    assert "skill" in str(error.value).lower()
    assert projects.list_my_projects(session) == []         # the whole transaction was undone


def test_update_replaces_fields_and_skills(make_student):
    session = make_student("j7")
    python, sql, git = _skill_id("Python"), _skill_id("SQL"), _skill_id("Git")
    project_id = _add(session, skill_ids=[python, sql])
    projects.update_project(session, project_id, "Renamed", "New description",
                            "2026-02-01", "2026-04-01", "https://example.org/new", [git])
    rows = projects.list_my_projects(session)
    assert len(rows) == 1
    row = rows[0]
    assert row["title"] == "Renamed"
    assert row["description"] == "New description"
    assert row["start_date"] == date(2026, 2, 1)
    assert row["end_date"] == date(2026, 4, 1)
    assert row["project_url"] == "https://example.org/new"
    assert row["skill_names"] == ["Git"]
    # empty values clear the optional fields and all skills
    projects.update_project(session, project_id, "Renamed", "New description",
                            "2026-02-01", None, None, None)
    row = projects.list_my_projects(session)[0]
    assert row["end_date"] is None
    assert row["project_url"] is None
    assert row["skill_names"] == []


def test_update_with_an_unknown_skill_changes_nothing(make_student):
    session = make_student("j8")
    project_id = _add(session, skill_ids=[_skill_id("Python")])
    before = projects.list_my_projects(session)
    with pytest.raises(validation.ValidationError):
        projects.update_project(session, project_id, "Changed", "Changed",
                                "2026-02-01", skill_ids=[999999])
    assert projects.list_my_projects(session) == before


def test_delete_project_removes_its_skill_links(make_student):
    session = make_student("j9")
    project_id = _add(session, skill_ids=[_skill_id("Python"), _skill_id("SQL")])
    projects.delete_project(session, project_id)
    assert projects.list_my_projects(session) == []
    links = database.fetch_one(
        "SELECT count(*) AS n FROM project_skill WHERE project_id = %s",
        (project_id,))["n"]
    assert links == 0
    with pytest.raises(validation.ValidationError) as error:    # nothing left to delete
        projects.delete_project(session, project_id)
    assert str(error.value) == projects.NOT_FOUND


def test_students_cannot_edit_or_delete_each_others_projects(make_student):
    a = make_student("j10a")
    b = make_student("j10b")
    project_id = _add(a, skill_ids=[_skill_id("Python")])
    before = projects.list_my_projects(a)
    with pytest.raises(validation.ValidationError) as error:
        projects.update_project(b, project_id, "Hacked", "Hacked", "2026-02-01",
                                skill_ids=[_skill_id("SQL")])
    assert str(error.value) == projects.NOT_FOUND           # same message as for a missing project
    with pytest.raises(validation.ValidationError) as error:
        projects.delete_project(b, project_id)
    assert str(error.value) == projects.NOT_FOUND
    assert projects.list_my_projects(a) == before           # a's project is untouched
    assert projects.list_my_projects(b) == []


def test_a_project_counts_as_project_evidence(make_student):
    session = make_student("j11")
    _add(session, skill_ids=[_skill_id("Python")])
    rows = skills.list_my_skills(session)
    assert len(rows) == 1
    row = rows[0]
    assert row["skill_name"] == "Python"
    assert row["declared_level_id"] is None                 # never declared
    assert row["project_count"] == 1
    assert row["strongest_evidence"] == "project"           # supports the skill, gives no level


def test_deleted_student_ends_the_session(make_student):
    session = make_student("j12")
    database.execute("DELETE FROM student WHERE student_id = %s", (session["student_id"],))
    with pytest.raises(auth.AuthError):
        _add(session)


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
            projects.list_my_projects(user)
        with pytest.raises(auth.PermissionDenied):
            projects.add_project(user, "Title", "Description", "2026-01-01")
        with pytest.raises(auth.PermissionDenied):
            projects.update_project(user, 1, "Title", "Description", "2026-01-01")
        with pytest.raises(auth.PermissionDenied):
            projects.delete_project(user, 1)