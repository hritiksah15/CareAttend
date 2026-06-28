#!/usr/bin/env python3
"""Calculate CareAttend SUS results from the response CSV."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from statistics import mean
from typing import Iterable


QUESTION_FIELDS = [f"q{i}" for i in range(1, 11)]
TASK_FIELDS = [
    ("task1_login_pass", "Login"),
    ("task2_assessment_pass", "Assessment"),
    ("task3_results_pass", "Results interpretation"),
    ("task4_bias_pass", "Bias monitoring"),
    ("task5_dark_mode_pass", "Dark mode"),
]


def normalise_bool(value: str) -> bool | None:
    cleaned = value.strip().lower()
    if cleaned in {"yes", "y", "true", "t", "1", "pass", "passed"}:
        return True
    if cleaned in {"no", "n", "false", "f", "0", "fail", "failed"}:
        return False
    if not cleaned:
        return None
    raise ValueError(f"invalid pass/fail value: {value!r}")


def sus_score(row: dict[str, str]) -> float | None:
    if any(not row.get(field, "").strip() for field in QUESTION_FIELDS):
        return None

    adjusted_total = 0
    for index, field in enumerate(QUESTION_FIELDS, start=1):
        raw = int(row[field])
        if raw < 1 or raw > 5:
            raise ValueError(f"{field} must be between 1 and 5")
        adjusted_total += raw - 1 if index % 2 else 5 - raw

    return adjusted_total * 2.5


def benchmark(score: float) -> str:
    if score >= 85:
        return "excellent"
    if score >= 80:
        return "strong"
    if score >= 68:
        return "above average"
    return "below target"


def task_rates(rows: Iterable[dict[str, str]]) -> list[tuple[str, int, int, float]]:
    materialised = list(rows)
    rates = []
    for field, label in TASK_FIELDS:
        answered = 0
        passed = 0
        for row in materialised:
            value = normalise_bool(row.get(field, ""))
            if value is None:
                continue
            answered += 1
            passed += int(value)
        rate = (passed / answered * 100) if answered else 0.0
        rates.append((label, passed, answered, rate))
    return rates


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Calculate CareAttend SUS score and task-completion summary."
    )
    parser.add_argument("csv_path", type=Path, help="Path to filled SUS response CSV.")
    parser.add_argument(
        "--min-participants",
        type=int,
        default=5,
        help="Minimum complete SUS responses required for valid evidence.",
    )
    args = parser.parse_args()

    with args.csv_path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    complete: list[tuple[str, float]] = []
    incomplete: list[str] = []
    errors: list[str] = []

    for row in rows:
        participant = row.get("participant_id", "").strip() or "unknown"
        try:
            score = sus_score(row)
        except (TypeError, ValueError) as exc:
            errors.append(f"{participant}: {exc}")
            continue
        if score is None:
            incomplete.append(participant)
            continue
        complete.append((participant, score))

    if errors:
        print("# SUS Results: invalid input")
        for error in errors:
            print(f"- {error}")
        return 1

    print("# SUS Results")
    print()
    print("| Participant | SUS score | Benchmark |")
    print("|---|---:|---|")
    for participant, score in complete:
        print(f"| {participant} | {score:.1f} | {benchmark(score)} |")

    print()
    if complete:
        mean_score = mean(score for _, score in complete)
        print(f"Mean SUS score: {mean_score:.1f}/100 ({benchmark(mean_score)})")
    else:
        print("Mean SUS score: pending")

    print(f"Complete participants: {len(complete)}/{args.min_participants}")
    if len(complete) < args.min_participants:
        print("Evidence status: pending; collect more complete real responses.")
    else:
        print("Evidence status: complete for 5-person SUS requirement.")

    if incomplete:
        print(f"Incomplete rows skipped: {', '.join(incomplete)}")

    print()
    print("## Task Completion")
    print()
    print("| Task | Passed | Responses | Rate |")
    print("|---|---:|---:|---:|")
    for label, passed, answered, rate in task_rates(rows):
        print(f"| {label} | {passed} | {answered} | {rate:.0f}% |")

    print()
    print("## Report Prompts")
    print()
    print("- Add the top 3 repeated qualitative findings.")
    print("- Link each major finding to a fix or a justified no-change decision.")
    print("- Compare the mean score with the 68+ target in the QA section.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
