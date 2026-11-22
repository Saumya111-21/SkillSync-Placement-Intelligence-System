"""Tests for app/security.py. They do not need the database."""

import pytest

from app import security

GOOD = "Correct-Horse-9"


def test_hash_is_not_the_password():
    """The stored value is an Argon2 hash and does not contain the password."""
    hashed = security.hash_password(GOOD)
    assert hashed.startswith("$argon2id$")
    assert GOOD not in hashed


def test_same_password_gives_different_hashes():
    """A random salt makes every hash different, even for the same password."""
    assert security.hash_password(GOOD) != security.hash_password(GOOD)


def test_correct_password_verifies():
    hashed = security.hash_password(GOOD)
    assert security.verify_password(GOOD, hashed) is True


def test_wrong_password_fails():
    hashed = security.hash_password(GOOD)
    assert security.verify_password("Wrong-Horse-9", hashed) is False
    assert security.verify_password(GOOD.lower(), hashed) is False


def test_placeholder_hash_is_rejected_without_error():
    """The sample accounts hold placeholder text, which must never log in."""
    placeholder = "SAMPLE-PLACEHOLDER-NOT-A-HASH"
    assert security.verify_password(GOOD, placeholder) is False


def test_missing_hash_is_rejected():
    assert security.verify_password(GOOD, None) is False
    assert security.verify_password(GOOD, "") is False
    assert security.verify_password(None, security.hash_password(GOOD)) is False


def test_overlong_password_is_rejected_at_login():
    """A huge input is refused before any hashing work is done."""
    hashed = security.hash_password(GOOD)
    assert security.verify_password("a1" * 200, hashed) is False


def test_weak_passwords_are_refused():
    weak = [
        "Short1",                  # too short
        "alllettersonlyhere",      # no digit
        "1234567890123",           # no letter
        "",                        # empty
        "a" * 129 + "1",           # too long
    ]
    for password in weak:
        with pytest.raises(ValueError):
            security.hash_password(password)


def test_strong_password_is_accepted():
    assert security.password_problems(GOOD) == []
    assert security.hash_password(GOOD)


def test_problems_are_listed():
    """A weak password gets one message per broken rule."""
    problems = security.password_problems("abc")
    assert len(problems) == 2          # too short, and no digit
    assert security.password_problems(None) == ["Password must be text."]