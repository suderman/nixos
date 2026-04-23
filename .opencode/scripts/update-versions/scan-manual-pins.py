#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_EXTENSIONS = {".nix"}

STRONG_PATTERNS = [
    re.compile(r"\bfetchurl\s*=|\bfetchurl\s*\{"),
    re.compile(r"\bfetchFromGitHub\s*\{"),
    re.compile(r"\bbuildFirefoxXpiAddon\s*\{"),
    re.compile(r'image\s*=\s*"[^\"]+:[^\"]+"'),
    re.compile(r"https?://[^\s\"]*(releases/download|downloads/file)"),
]

CANDIDATE_PATTERNS = [
    re.compile(r'\bversion\s*=\s*"[^\"]+"'),
    re.compile(r'\brev\s*=\s*"[^\"]+"'),
    re.compile(r'\btag\s*=\s*"[^\"]+"'),
    re.compile(r'\burl\s*=\s*"https?://[^\"]+"'),
    re.compile(r'\bsha256\s*=\s*"[^\"]+"'),
    re.compile(r'\bhash\s*=\s*"[^\"]+"'),
    re.compile(r'image\s*=\s*"[^\"]+:[^\"]+"'),
    re.compile(r"https?://[^\s\"]*(releases/download|downloads/file)"),
]


def is_excluded(relative_path: Path) -> bool:
    text = relative_path.as_posix()
    if text.startswith(".opencode/node_modules/"):
        return True

    parts = set(relative_path.parts)
    if parts & {".git", ".direnv", ".devenv", "node_modules", "secrets"}:
        return True

    return any(part.startswith("result") for part in relative_path.parts)


def strong_line_indexes(lines: list[str]) -> set[int]:
    indexes: set[int] = set()
    for idx, line in enumerate(lines):
        if any(pattern.search(line) for pattern in STRONG_PATTERNS):
            indexes.add(idx)
    return indexes


def collect_matches(file_path: Path) -> list[dict[str, str | int]]:
    text = file_path.read_text()
    lines = text.splitlines()
    strong_indexes = strong_line_indexes(lines)
    if not strong_indexes:
        return []

    matches: list[dict[str, str | int]] = []
    for idx, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue

        if not any(pattern.search(line) for pattern in CANDIDATE_PATTERNS):
            continue

        matches.append(
            {
                "line": idx + 1,
                "text": line.rstrip(),
            }
        )

    return matches


def scan(root: Path) -> dict[str, list[dict[str, str | int]]]:
    results: dict[str, list[dict[str, str | int]]] = {}

    for file_path in sorted(root.rglob("*")):
        if not file_path.is_file() or file_path.suffix not in DEFAULT_EXTENSIONS:
            continue

        relative_path = file_path.relative_to(root)
        if is_excluded(relative_path):
            continue

        matches = collect_matches(file_path)
        if matches:
            results[relative_path.as_posix()] = matches

    return results


def render_markdown(results: dict[str, list[dict[str, str | int]]]) -> str:
    if not results:
        return "No candidate manual dependency pins found."

    lines: list[str] = []
    for path, matches in results.items():
        lines.append(f"## {path}")
        lines.append("")
        for match in matches:
            lines.append(f"- L{match['line']}: `{match['text']}`")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Scan the repo for likely manual dependency pins outside flake inputs."
    )
    parser.add_argument(
        "--root",
        default=str(REPO_ROOT),
        help="Repo root to scan",
    )
    parser.add_argument(
        "--format",
        choices=("markdown", "json"),
        default="markdown",
        help="Output format",
    )
    args = parser.parse_args()

    results = scan(Path(args.root).resolve())
    if args.format == "json":
        print(json.dumps(results, indent=2, sort_keys=True))
    else:
        print(render_markdown(results), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
