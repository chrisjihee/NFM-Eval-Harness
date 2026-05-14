"""Helpers for Open Telco custom lm-eval tasks."""

from __future__ import annotations

import string
from typing import Any


CHOICE_LABELS = tuple(string.ascii_uppercase)


def _format_choices(choices: list[str]) -> str:
    lines = []
    for idx, choice in enumerate(choices):
        label = CHOICE_LABELS[idx]
        lines.append(f"{label}. {choice}")
    return "\n".join(lines)


def doc_to_text_mc(doc: dict[str, Any]) -> str:
    question = doc["question"].strip()
    choices = doc["choices"]
    return (
        "You are answering a telecommunications domain benchmark question.\n"
        "Select the single best answer.\n\n"
        f"Question: {question}\n"
        "Choices:\n"
        f"{_format_choices(choices)}\n\n"
        "Answer:"
    )


def doc_to_text_3gpp_tsg(doc: dict[str, Any]) -> str:
    question = doc["question"].strip()
    return (
        "You are answering a 3GPP working-group classification question.\n"
        "Return only the most likely working group label.\n\n"
        f"Question: {question}\n\n"
        "Answer:"
    )
