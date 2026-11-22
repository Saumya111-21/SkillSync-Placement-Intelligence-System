"""Input checks for SkillSync.

Every function returns the cleaned value or raises ValidationError with a
readable message. Validation keeps bad data out of the database. It does not
replace parameterized queries, which are what stop SQL injection.
"""

import re
from datetime import date, datetime

EMAIL_PATTERN = re.compile(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+")


class ValidationError(ValueError):
    """The user's input is not acceptable."""


def _as_text(value, label) -> str:
    if value is None:
        return ""
    if not isinstance(value, str):
        raise ValidationError(f"{label} must be text.")
    return value.strip()


def clean_text(value, label, max_length, required=True):
    """Trim the text and check its length. Returns None for an empty optional value."""
    text = _as_text(value, label)
    if not text:
        if required:
            raise ValidationError(f"{label} is required.")
        return None
    if len(text) > max_length:
        raise ValidationError(f"{label} must have at most {max_length} characters.")
    if any(ord(ch) < 32 or ord(ch) == 127 for ch in text):
        raise ValidationError(f"{label} contains characters that are not allowed.")
    return text


def clean_email(value) -> str:
    """Return the email in lower case, or raise ValidationError."""
    text = _as_text(value, "Email").lower()
    if not text:
        raise ValidationError("Email is required.")
    if len(text) > 255 or not EMAIL_PATTERN.fullmatch(text):
        raise ValidationError("Enter a valid email address.")
    return text


def clean_phone(value):
    """Optional. Spaces and hyphens are removed. 10 to 14 digits, may start with +."""
    text = _as_text(value, "Phone")
    if not text:
        return None
    compact = re.sub(r"[ \-]", "", text)
    if not re.fullmatch(r"\+?\d{10,14}", compact):
        raise ValidationError(
            "Phone must have 10 to 14 digits, and may start with +."
        )
    return compact


def clean_int(value, label, minimum, maximum) -> int:
    """A whole number between minimum and maximum. Accepts 7 or the text "7"."""
    if isinstance(value, bool) or not isinstance(value, (int, str)):
        raise ValidationError(f"{label} must be a whole number.")
    if isinstance(value, str):
        value = value.strip()
        if not re.fullmatch(r"-?\d+", value):
            raise ValidationError(f"{label} must be a whole number.")
    number = int(value)
    if not minimum <= number <= maximum:
        raise ValidationError(f"{label} must be between {minimum} and {maximum}.")
    return number


def clean_choice(value, label, allowed):
    """The value must be one of the allowed values."""
    text = _as_text(value, label)
    if text not in allowed:
        raise ValidationError(f"{label} must be one of: {', '.join(allowed)}.")
    return text


def clean_date(value, label) -> date:
    """A date, or text in the form YYYY-MM-DD."""
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    text = _as_text(value, label)
    try:
        return date.fromisoformat(text)
    except ValueError:
        raise ValidationError(f"{label} must be a date in the form YYYY-MM-DD.") from None


def clean_url(value, label="Link", max_length=500):
    """Optional web link. Must start with http:// or https://."""
    text = _as_text(value, label)
    if not text:
        return None
    if len(text) > max_length:
        raise ValidationError(f"{label} must have at most {max_length} characters.")
    if not re.fullmatch(r"https?://\S+", text):
        raise ValidationError(f"{label} must start with http:// or https://.")
    return text