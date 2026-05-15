"""Helpers for Open Telco custom lm-eval tasks."""

from __future__ import annotations

import re
import string
from typing import Any


CHOICE_LABELS = tuple(string.ascii_uppercase)
THREE_GPP_LABELS = (
    "CT1",
    "CT3",
    "CT4",
    "CT6",
    "RAN1",
    "RAN2",
    "RAN3",
    "RAN4",
    "RAN5",
    "RAN_AH1",
    "SA1",
    "SA2",
    "SA3",
    "SA4",
    "SA5",
    "SA6",
)


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


def _extract_3gpp_excerpt(question: str) -> str:
    match = re.search(r"###TEXT:\s*\{(.*)\}\s*$", question.strip(), flags=re.DOTALL)
    if match:
        return match.group(1).strip()
    return question.strip()


def doc_to_text_3gpp_mc(doc: dict[str, Any]) -> str:
    excerpt = _extract_3gpp_excerpt(doc["question"])
    return (
        "You are classifying a 3GPP document excerpt by working group.\n"
        "Select the single best answer from the choices.\n\n"
        f"Document excerpt:\n{excerpt}\n\n"
        "Choices:\n"
        f"{_format_choices(list(THREE_GPP_LABELS))}\n\n"
        "Answer:"
    )


def doc_to_choice_3gpp_tsg(doc: dict[str, Any]) -> list[str]:
    del doc
    return list(THREE_GPP_LABELS)


def doc_to_target_3gpp_tsg(doc: dict[str, Any]) -> int:
    return THREE_GPP_LABELS.index(doc["answer"])
