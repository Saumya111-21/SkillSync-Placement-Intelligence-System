"""Database connection helpers for SkillSync.

Every part of the application gets its database connection from here, so the
settings, the error messages and the transaction rules live in one place.
"""

import os
from contextlib import contextmanager
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from psycopg.rows import dict_row

# Read the settings from the .env file in the project root (the folder above app/).
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

REQUIRED_SETTINGS = ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD")


class DatabaseError(Exception):
    """The database could not be reached or the settings are missing."""


def _settings() -> dict:
    """Collect the connection settings from the environment."""
    missing = [name for name in REQUIRED_SETTINGS if not os.getenv(name)]
    if missing:
        raise DatabaseError("Missing settings in .env: " + ", ".join(missing))
    try:
        port = int(os.environ["DB_PORT"])
    except ValueError:
        raise DatabaseError("DB_PORT in .env must be a number") from None
    return {
        "host": os.environ["DB_HOST"],
        "port": port,
        "dbname": os.environ["DB_NAME"],
        "user": os.environ["DB_USER"],
        "password": os.environ["DB_PASSWORD"],
    }


def get_connection():
    """Open a connection. Rows come back as dictionaries (column name -> value)."""
    settings = _settings()
    try:
        return psycopg.connect(**settings, row_factory=dict_row, connect_timeout=5)
    except psycopg.OperationalError as exc:
        raise DatabaseError(
            "Could not connect to the database. Is PostgreSQL running, "
            "and are the settings in .env correct?"
        ) from exc


@contextmanager
def transaction():
    """Give a connection; commit if the code succeeds, roll back if it fails."""
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def fetch_all(sql, params=None) -> list:
    """Run a SELECT and return every row as a list of dictionaries."""
    with transaction() as conn:
        return conn.execute(sql, params).fetchall()


def fetch_one(sql, params=None):
    """Run a SELECT and return the first row as a dictionary, or None."""
    with transaction() as conn:
        return conn.execute(sql, params).fetchone()


def execute(sql, params=None) -> int:
    """Run an INSERT, UPDATE or DELETE and return how many rows it changed."""
    with transaction() as conn:
        return conn.execute(sql, params).rowcount


def check_connection() -> dict:
    """Ask PostgreSQL who we are. Used to test the connection."""
    return fetch_one(
        "SELECT current_user AS user_name, current_database() AS database_name, "
        "version() AS server_version"
    )


if __name__ == "__main__":
    try:
        info = check_connection()
    except DatabaseError as exc:
        print(exc)
        raise SystemExit(1)
    print(f"Connected as {info['user_name']} to database {info['database_name']}")
    print(info["server_version"])