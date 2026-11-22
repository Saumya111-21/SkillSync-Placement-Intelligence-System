"""Tests for app/validation.py. They do not need the database."""

from datetime import date, datetime

import pytest

from app import validation as v


def test_text_is_trimmed():
    assert v.clean_text("  Asha  ", "Name", 50) == "Asha"


def test_required_text_cannot_be_empty():
    for empty in ("", "   ", None):
        with pytest.raises(v.ValidationError):
            v.clean_text(empty, "Name", 50)


def test_optional_empty_text_gives_none():
    assert v.clean_text("  ", "Notes", 50, required=False) is None
    assert v.clean_text(None, "Notes", 50, required=False) is None


def test_text_length_control_characters_and_types_are_refused():
    with pytest.raises(v.ValidationError):
        v.clean_text("a" * 51, "Name", 50)
    with pytest.raises(v.ValidationError):
        v.clean_text("bad\x00text", "Name", 50)
    with pytest.raises(v.ValidationError):
        v.clean_text("line one\nline two", "Name", 50)
    with pytest.raises(v.ValidationError):
        v.clean_text(123, "Name", 50)


def test_email_is_cleaned():
    assert v.clean_email("  Asha@Example.ORG ") == "asha@example.org"
    assert v.clean_email("first.last+tag@mail.example.co.in") == "first.last+tag@mail.example.co.in"


def test_bad_emails_are_refused():
    bad = ["", None, "not-an-email", "a@b", "a b@example.org", "@example.org",
           "a@@example.org", "a@example..org", "a" * 250 + "@example.org"]
    for email in bad:
        with pytest.raises(v.ValidationError):
            v.clean_email(email)


def test_phone_is_cleaned():
    assert v.clean_phone("98100 00001") == "9810000001"
    assert v.clean_phone("+91 98100-00001") == "+919810000001"
    assert v.clean_phone("") is None
    assert v.clean_phone(None) is None


def test_bad_phones_are_refused():
    for phone in ("12345", "abcdefghij", "98100000011111111", "+91-(981)0000001"):
        with pytest.raises(v.ValidationError):
            v.clean_phone(phone)


def test_int_accepts_numbers_and_numeric_text():
    assert v.clean_int(7, "Semester", 1, 8) == 7
    assert v.clean_int("7", "Semester", 1, 8) == 7
    assert v.clean_int(" 3 ", "Semester", 1, 8) == 3
    assert v.clean_int(1, "Semester", 1, 8) == 1      # lower boundary
    assert v.clean_int(8, "Semester", 1, 8) == 8      # upper boundary


def test_bad_ints_are_refused():
    for value in (0, 9, "9", "abc", "3.5", 3.5, True, None, "", [1]):
        with pytest.raises(v.ValidationError):
            v.clean_int(value, "Semester", 1, 8)


def test_choice_must_be_one_of_the_allowed_values():
    allowed = ("online", "in_person")
    assert v.clean_choice("online", "Mode", allowed) == "online"
    for value in ("phone", "", None, "Online"):
        with pytest.raises(v.ValidationError):
            v.clean_choice(value, "Mode", allowed)


def test_dates_are_accepted_in_three_forms():
    assert v.clean_date("2026-04-30", "Start date") == date(2026, 4, 30)
    assert v.clean_date(date(2026, 4, 30), "Start date") == date(2026, 4, 30)
    assert v.clean_date(datetime(2026, 4, 30, 9, 15), "Start date") == date(2026, 4, 30)


def test_bad_dates_are_refused():
    for value in ("30-04-2026", "2026-13-45", "2026-02-30", "not a date", "", None):
        with pytest.raises(v.ValidationError):
            v.clean_date(value, "Start date")


def test_urls_are_accepted_or_empty():
    assert v.clean_url("https://example.org/page") == "https://example.org/page"
    assert v.clean_url("http://localhost:8501") == "http://localhost:8501"
    assert v.clean_url("") is None
    assert v.clean_url(None) is None


def test_bad_urls_are_refused():
    bad = ["ftp://example.org", "example.org", "javascript:alert(1)",
           "https://exa mple.org", "https://" + "a" * 500]
    for url in bad:
        with pytest.raises(v.ValidationError):
            v.clean_url(url)