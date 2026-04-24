"""Extract ordered implementation steps from `implement-plan.md`.

The planner writes a Markdown file with a section titled "Implementation steps"
containing an ordered list (numbered or bulleted). We parse that section into
`[{index, title}]` so the frontend can render a checklist that fills in as the
implementor announces `STEP:` markers.

Robustness goals:
- Match common heading variants (`## 4. Implementation steps`, `### Steps`, etc.).
- Stop at the next sibling-or-higher heading.
- Treat top-level numbered/bulleted items as steps; ignore nested bullets.
"""
from __future__ import annotations

import re
from pathlib import Path
from typing import Iterable


HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
STEPS_HEADING_RE = re.compile(
    r"(implementation\s+steps?|^steps?$|implement\s+steps?)",
    re.IGNORECASE,
)
NUMBERED_ITEM_RE = re.compile(r"^\s{0,3}(\d+)[.)]\s+(.+?)\s*$")
BULLET_ITEM_RE = re.compile(r"^\s{0,3}[-*+]\s+(.+?)\s*$")
NESTED_RE = re.compile(r"^\s{4,}")


def parse_plan_steps(text: str) -> list[dict]:
    lines = text.splitlines()
    section = _extract_steps_section(lines)
    return _items_from_section(section)


def parse_plan_file(path: Path) -> list[dict]:
    if not path.exists():
        return []
    try:
        return parse_plan_steps(path.read_text())
    except OSError:
        return []


def _extract_steps_section(lines: list[str]) -> list[str]:
    start: int | None = None
    start_level = 0
    for i, line in enumerate(lines):
        m = HEADING_RE.match(line)
        if not m:
            continue
        level = len(m.group(1))
        title = m.group(2)
        if STEPS_HEADING_RE.search(_strip_leading_number(title)):
            start = i + 1
            start_level = level
            break
    if start is None:
        return []
    end = len(lines)
    for j in range(start, len(lines)):
        m = HEADING_RE.match(lines[j])
        if m and len(m.group(1)) <= start_level:
            end = j
            break
    return lines[start:end]


def _items_from_section(section: list[str]) -> list[dict]:
    items: list[str] = []
    for line in section:
        if not line.strip():
            continue
        if NESTED_RE.match(line):
            # Nested bullet — treat as continuation of the last item.
            if items:
                items[-1] = f"{items[-1]} {line.strip()}"
            continue
        m = NUMBERED_ITEM_RE.match(line)
        if m:
            items.append(_clean(m.group(2)))
            continue
        m = BULLET_ITEM_RE.match(line)
        if m:
            items.append(_clean(m.group(1)))
            continue
        # Free-text continuation of the previous item.
        if items:
            items[-1] = f"{items[-1]} {line.strip()}"
    return [{"index": idx + 1, "title": _truncate(t, 200)} for idx, t in enumerate(items)]


def _clean(s: str) -> str:
    # Strip trailing markdown emphasis fences like `**bold**` markers around the whole line.
    return re.sub(r"\s+", " ", s).strip()


def _strip_leading_number(s: str) -> str:
    return re.sub(r"^\d+[.)]\s*", "", s)


def _truncate(s: str, n: int) -> str:
    return s if len(s) <= n else s[: n - 1] + "…"


__all__: Iterable[str] = ("parse_plan_steps", "parse_plan_file")
