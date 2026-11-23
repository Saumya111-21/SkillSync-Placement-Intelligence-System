"""Student functions for SkillSync. Every function checks the role first."""

from .. import auth


def current_student_id(user) -> int:
    """The student id of the logged-in student. Raises PermissionDenied for anyone else."""
    auth.require_role(user, "student")
    student_id = user.get("student_id")
    if isinstance(student_id, bool) or not isinstance(student_id, int):
        raise auth.PermissionDenied("You are not allowed to do this.")
    return student_id