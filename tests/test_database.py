"""Tests for app/database.py. They need PostgreSQL running with the skillsync database."""

import pytest

from app import database


def test_connection_identity():
    """The module connects with the right user to the right database."""
    info = database.check_connection()
    assert info["user_name"] == "skillsync_app"
    assert info["database_name"] == "skillsync"


def test_fetch_all_returns_dictionaries():
    """Rows come back as dictionaries with column names as keys."""
    rows = database.fetch_all(
        "SELECT level_id, level_name FROM proficiency_level ORDER BY level_id"
    )
    assert len(rows) == 4
    assert rows[0] == {"level_id": 1, "level_name": "Beginner"}


def test_fetch_one_returns_none_when_nothing_found():
    """An unknown row gives None, not an error."""
    row = database.fetch_one(
        "SELECT * FROM skill WHERE skill_name = %s", ("No Such Skill 12345",)
    )
    assert row is None


def test_parameters_are_never_run_as_sql():
    """A value that looks like SQL injection is treated as plain text."""
    nasty = "x'; DROP TABLE skill; --"
    assert database.fetch_one(
        "SELECT * FROM skill WHERE skill_name = %s", (nasty,)
    ) is None
    # The table is still there and still has its rows.
    assert database.fetch_one("SELECT count(*) AS n FROM skill")["n"] >= 30


def test_failed_transaction_is_rolled_back():
    """If the code fails halfway, nothing from that transaction is kept."""
    with pytest.raises(RuntimeError):
        with database.transaction() as conn:
            conn.execute(
                "INSERT INTO department (department_name) VALUES (%s)",
                ("Rollback Test Department",),
            )
            raise RuntimeError("simulated failure")
    assert database.fetch_one(
        "SELECT * FROM department WHERE department_name = %s",
        ("Rollback Test Department",),
    ) is None


def test_missing_setting_gives_a_clear_error(monkeypatch):
    """A missing setting gives a readable message, not a long traceback."""
    monkeypatch.delenv("DB_PASSWORD", raising=False)
    with pytest.raises(database.DatabaseError) as error:
        database.get_connection()
    assert "DB_PASSWORD" in str(error.value)