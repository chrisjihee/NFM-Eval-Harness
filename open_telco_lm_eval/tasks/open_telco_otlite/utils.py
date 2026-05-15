"""Helpers for Open Telco custom lm-eval tasks."""

from __future__ import annotations

import json
import math
import os
import re
import string
from fractions import Fraction
from pathlib import Path
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
THREE_GPP_LABEL_SET = frozenset(THREE_GPP_LABELS)
ROOT_CAUSE_LABELS = tuple(f"C{i}" for i in range(1, 9))
ROOT_CAUSE_LABEL_SET = frozenset(ROOT_CAUSE_LABELS)
ROOT_DIR = Path(__file__).resolve().parents[3]
BOXED_RE = re.compile(r"\\boxed\{([^{}]+)\}")
NUMBER_RE = re.compile(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?|[-+]?\d+\s*/\s*[-+]?\d+")
WORKING_GROUP_RE = re.compile(
    r'["\']?WORKING\s*GROUP["\']?\s*:\s*["\']?([A-Za-z0-9_]+)["\']?',
    flags=re.IGNORECASE,
)
FINAL_ANSWER_RE = re.compile(
    r"(?:final answer|answer)\s*(?:is|:)\s*([^\n\r.;]+)",
    flags=re.IGNORECASE,
)
ROOT_CAUSE_RE = re.compile(r"\bC([1-8])\b", flags=re.IGNORECASE)


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


def doc_to_target_text(doc: dict[str, Any]) -> str:
    return str(doc["answer"]).strip()


def doc_to_text_3gpp_generate(doc: dict[str, Any]) -> str:
    excerpt = _extract_3gpp_excerpt(doc["question"])
    labels = ", ".join(THREE_GPP_LABELS)
    return (
        "You are classifying a 3GPP technical-document excerpt by working group.\n"
        f"Choose exactly one label from: {labels}.\n"
        'Return only JSON in this format: {"WORKING GROUP": "LABEL"}.\n\n'
        f"Document excerpt:\n{excerpt}\n\n"
        "Answer:"
    )


def _normalize_token(text: str) -> str:
    return text.strip().upper().replace("-", "_").replace(" ", "_")


def extract_3gpp_label(text: str) -> str | None:
    if not isinstance(text, str):
        return None

    text = text.strip()
    if not text:
        return None

    try:
        parsed = json.loads(text)
        if isinstance(parsed, dict):
            value = parsed.get("WORKING GROUP") or parsed.get("working group")
            if isinstance(value, str):
                normalized = _normalize_token(value)
                if normalized in THREE_GPP_LABEL_SET:
                    return normalized
    except json.JSONDecodeError:
        pass

    match = WORKING_GROUP_RE.search(text)
    if match:
        normalized = _normalize_token(match.group(1))
        if normalized in THREE_GPP_LABEL_SET:
            return normalized

    for label in sorted(THREE_GPP_LABELS, key=len, reverse=True):
        if re.search(rf"\b{re.escape(label)}\b", text, flags=re.IGNORECASE):
            return label

    return None


def process_results_3gpp_generate(
    doc: dict[str, Any], results: list[str]
) -> dict[str, int]:
    prediction = extract_3gpp_label(results[0] if results else "")
    gold = _normalize_token(str(doc["answer"]))
    return {"acc": int(prediction == gold)}


def doc_to_text_telemath(doc: dict[str, Any]) -> str:
    question = doc["question"].strip()
    return (
        "You are solving a telecommunications math problem.\n"
        "Return only the final numeric answer.\n"
        "If needed, you may use scientific notation.\n\n"
        f"Problem: {question}\n"
        "Answer:"
    )


def _clean_numeric_text(text: str) -> str:
    cleaned = text.strip()
    cleaned = cleaned.replace(",", "")
    cleaned = cleaned.replace("$", "")
    cleaned = cleaned.replace("\\(", "").replace("\\)", "")
    cleaned = cleaned.replace("{", "").replace("}", "")
    return cleaned.strip()


def _coerce_number(text: str) -> float | None:
    candidate = _clean_numeric_text(text)
    if not candidate:
        return None

    if re.fullmatch(r"[-+]?\d+\s*/\s*[-+]?\d+", candidate):
        try:
            return float(Fraction(candidate.replace(" ", "")))
        except (ValueError, ZeroDivisionError):
            return None

    try:
        return float(candidate)
    except ValueError:
        return None


def extract_telemath_answer(text: str) -> float | None:
    if not isinstance(text, str):
        return None

    boxed = BOXED_RE.findall(text)
    if boxed:
        number = _coerce_number(boxed[-1])
        if number is not None:
            return number

    final_answer = FINAL_ANSWER_RE.search(text)
    if final_answer:
        number = _coerce_number(final_answer.group(1))
        if number is not None:
            return number

    numbers = NUMBER_RE.findall(text)
    for candidate in reversed(numbers):
        number = _coerce_number(candidate)
        if number is not None:
            return number

    return None


def process_results_telemath(
    doc: dict[str, Any], results: list[str]
) -> dict[str, int]:
    prediction = extract_telemath_answer(results[0] if results else "")
    gold = _coerce_number(str(doc["answer"]))
    if prediction is None or gold is None:
        return {"acc": 0}

    return {"acc": int(math.isclose(prediction, gold, rel_tol=1e-6, abs_tol=1e-8))}


def doc_to_text_telelogs(doc: dict[str, Any]) -> str:
    question = doc["question"].strip()
    return (
        f"{question}\n\n"
        "Return only the final root-cause label such as C1, C2, ..., or C8.\n"
        "Answer:"
    )


def extract_telelogs_label(text: str) -> str | None:
    if not isinstance(text, str):
        return None

    boxed = BOXED_RE.findall(text)
    for candidate in reversed(boxed):
        candidate = candidate.strip().upper()
        if candidate in ROOT_CAUSE_LABEL_SET:
            return candidate
        if re.fullmatch(r"[1-8]", candidate):
            return f"C{candidate}"

    matches = ROOT_CAUSE_RE.findall(text)
    if matches:
        return f"C{matches[-1]}"

    numbers = re.findall(r"\b([1-8])\b", text)
    if numbers:
        return f"C{numbers[-1]}"

    return None


def process_results_telelogs(
    doc: dict[str, Any], results: list[str]
) -> dict[str, int]:
    prediction = extract_telelogs_label(results[0] if results else "")
    gold = str(doc["answer"]).strip().upper()
    return {"acc": int(prediction == gold)}


def _teletables_roots() -> list[Path]:
    env_root = os.environ.get("TELETABLES_ROOT")
    roots = [
        Path(env_root) if env_root else None,
        ROOT_DIR / "tables",
        ROOT_DIR / "data" / "TeleTables" / "tables",
        ROOT_DIR / ".cache_hf" / "TeleTables" / "tables",
    ]
    return [root for root in roots if root is not None]


def _load_teletable_context(doc: dict[str, Any]) -> str | None:
    document_id = str(doc["document_id"]).strip()
    table_id = str(doc["table_id"]).strip()
    candidate_suffixes = ("table.md", "table.html", "table.json")

    for root in _teletables_roots():
        for suffix in candidate_suffixes:
            table_path = root / document_id / table_id / suffix
            if table_path.is_file():
                try:
                    content = table_path.read_text(encoding="utf-8").strip()
                except UnicodeDecodeError:
                    content = table_path.read_text(encoding="latin-1").strip()
                if content:
                    if len(content) > 12000:
                        content = content[:12000].rstrip() + "\n...[truncated]"
                    return f"{suffix}:\n{content}"
    return None


def doc_to_text_teletables(doc: dict[str, Any]) -> str:
    metadata = (
        f"Table title: {doc['table_title'].strip()}\n"
        f"Document title: {doc['document_title'].strip()}"
    )
    table_context = _load_teletable_context(doc)
    if table_context:
        context_block = f"Table content:\n{table_context}"
    else:
        context_block = (
            "Table content: [not available in the public GSMA/ot-full row; "
            "set TELETABLES_ROOT to the extracted TeleTables tables directory to "
            "inject the original table content automatically]"
        )

    return (
        "You are answering a telecommunications table-understanding question.\n"
        "Use the table metadata and any available table content to select the "
        "single best answer.\n\n"
        f"{metadata}\n"
        f"{context_block}\n\n"
        f"Question: {doc['question'].strip()}\n"
        "Choices:\n"
        f"{_format_choices(doc['choices'])}\n\n"
        "Answer:"
    )
