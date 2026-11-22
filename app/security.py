"""Password hashing and password rules for SkillSync.

Passwords are never stored, logged or returned. The database holds only the
Argon2 hash, which includes a random salt, so two users with the same
password get different hashes.
"""

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError

MIN_LENGTH = 10
MAX_LENGTH = 128

_hasher = PasswordHasher()


def password_problems(password) -> list:
    """Return the reasons a password is too weak. An empty list means it is fine."""
    if not isinstance(password, str):
        return ["Password must be text."]
    problems = []
    if len(password) < MIN_LENGTH:
        problems.append(f"Password must have at least {MIN_LENGTH} characters.")
    if len(password) > MAX_LENGTH:
        problems.append(f"Password must have at most {MAX_LENGTH} characters.")
    if not any(ch.isalpha() for ch in password):
        problems.append("Password must contain at least one letter.")
    if not any(ch.isdigit() for ch in password):
        problems.append("Password must contain at least one digit.")
    return problems


def hash_password(password: str) -> str:
    """Return the Argon2 hash to store. Raises ValueError for a weak password."""
    problems = password_problems(password)
    if problems:
        raise ValueError(" ".join(problems))
    return _hasher.hash(password)


def verify_password(password, stored_hash) -> bool:
    """True only if the password matches the stored hash. Never raises."""
    if not isinstance(password, str) or not isinstance(stored_hash, str):
        return False
    if not stored_hash or len(password) > MAX_LENGTH:
        return False
    try:
        return _hasher.verify(stored_hash, password)
    except (VerificationError, InvalidHashError):
        # Wrong password, or the stored value is not a real hash
        # (for example the placeholder text in the sample data).
        return False