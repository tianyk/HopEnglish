#!/usr/bin/env python3
"""Check local documentation links and the repository's memory file contract."""

from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parent.parent
DAILY_HEADING = re.compile(r"^## (\d{2}:\d{2}) \[([^\]\n]+)\]$", re.MULTILINE)
LINK = re.compile(r"!?\[[^\]\n]*\]\((<[^>\n]+>|[^\s)]+)(?:\s+\"[^\"]*\")?\)")
REQUIRED = (
    "AGENTS.md",
    "docs/README.md",
    "docs/product_status.md",
    "docs/ios_release.md",
    "docs/guide/README.md",
    "docs/guide/architecture.md",
    "docs/guide/flutter-ui.md",
    "docs/guide/components.md",
    "docs/guide/learning.md",
    "docs/guide/persistence.md",
    "docs/guide/audio-lifecycle.md",
    "docs/guide/content-assets.md",
    "docs/guide/verification.md",
    ".agents/skills/test-case-generator/SKILL.md",
    ".agents/skills/learning-flow-review/SKILL.md",
    ".memory/SUMMARY.md",
    ".memory/PITFALLS.md",
    ".memory/PLAYBOOKS.md",
)


def markdown_files(root):
    files = {root / name for name in ("AGENTS.md", "README.md", "README.en.md", "PRD.md")}
    for directory in ("docs", ".agents", ".memory"):
        files.update((root / directory).rglob("*.md"))
    files.update((root / "assets").glob("*/README.md"))
    files.update((root / "scripts").glob("*/README.md"))
    return sorted(path for path in files if path.is_file())


def check_markdown(root, path):
    errors = []
    fence = None
    relative = path.relative_to(root)
    for number, line in enumerate(path.read_text().splitlines(), 1):
        marker = re.match(r"^\s*(`{3,}|~{3,})", line)
        if marker:
            value = marker.group(1)
            if fence is None:
                fence = (value[0], len(value), number)
            elif value[0] == fence[0] and len(value) >= fence[1]:
                fence = None
            continue
        if fence:
            continue
        prose = re.sub(r"`+[^`]*`+", "", line)
        for match in LINK.finditer(prose):
            target = match.group(1).strip("<>")
            parts = urlsplit(target)
            if parts.scheme or parts.netloc or not parts.path:
                continue
            destination = path.parent / unquote(parts.path)
            if not destination.exists():
                errors.append(f"{relative}:{number}: local link does not exist: {target}")
    if fence:
        errors.append(f"{relative}:{fence[2]}: unclosed fenced code block")
    return errors


def sections(text, heading_pattern):
    matches = list(heading_pattern.finditer(text))
    return [
        (match, text[match.end(): matches[index + 1].start() if index + 1 < len(matches) else len(text)])
        for index, match in enumerate(matches)
    ]


def check_memory(root):
    errors = []
    memory = root / ".memory"
    summary_path = memory / "SUMMARY.md"
    if summary_path.is_file():
        summary = summary_path.read_text()
        entries = [line for line in summary.splitlines() if line.startswith("- ")]
        if len(summary) > 2200 or len(entries) > 15 or any(len(line) > 180 for line in entries):
            errors.append(".memory/SUMMARY.md: exceeds 15 entries / 2200 characters / 180 per entry")
        if not re.search(r"^最近整理：\d{4}-\d{2}-\d{2}$", summary, re.MULTILINE):
            errors.append(".memory/SUMMARY.md: missing 最近整理 date")
        cursor = re.search(
            r"^整理截至：(daily/\d{4}-\d{2}-\d{2}\.md) 的 (\d{2}:\d{2} \[[^\]\n]+\])$",
            summary,
            re.MULTILINE,
        )
        if not cursor:
            errors.append(".memory/SUMMARY.md: missing exact Daily cursor")
        else:
            daily = memory / cursor.group(1)
            if not daily.is_file() or f"## {cursor.group(2)}" not in daily.read_text().splitlines():
                errors.append(".memory/SUMMARY.md: Daily cursor does not match an existing record")

    daily_files = sorted((memory / "daily").glob("*.md"))
    if not daily_files:
        errors.append(".memory/daily/: no initial handoff record")
    for path in daily_files:
        relative = path.relative_to(root)
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}\.md", path.name):
            errors.append(f"{relative}: expected YYYY-MM-DD.md")
        text = path.read_text()
        records = sections(text, DAILY_HEADING)
        if not records:
            errors.append(f"{relative}: missing ## HH:MM [agent] record")
        for match, body in records:
            record = f"{match.group(0)}\n{body}".strip()
            bullets = [line for line in body.splitlines() if line.startswith("- ")]
            if len(record) > 300 or not 1 <= len(bullets) <= 3:
                errors.append(f"{relative}: {match.group(1)} exceeds 300 characters or 1–3 bullets")

    pitfalls_path = memory / "PITFALLS.md"
    if pitfalls_path.is_file():
        pitfalls = sections(pitfalls_path.read_text(), re.compile(r"^\*\*[^\n]+\*\*\s*$", re.MULTILINE))
        if len(pitfalls) > 20:
            errors.append(".memory/PITFALLS.md: exceeds 20 active entries")
        for match, body in pitfalls:
            if not all(label in body for label in ("为什么：", "证据：", "Seen")):
                errors.append(f".memory/PITFALLS.md: entry missing reason, evidence, or Seen: {match.group(0)}")

    playbooks_path = memory / "PLAYBOOKS.md"
    if playbooks_path.is_file():
        playbooks_text = playbooks_path.read_text()
        playbooks = sections(playbooks_text, re.compile(r"^## [^\n]+$", re.MULTILINE))
        if len(playbooks_text) > 3000 or len(playbooks) > 6:
            errors.append(".memory/PLAYBOOKS.md: exceeds 6 playbooks / 3000 characters")
        for match, body in playbooks:
            steps = re.findall(r"^\d+\. ", body, re.MULTILINE)
            if "何时使用：" not in body or "来源：" not in body or not 3 <= len(steps) <= 5:
                errors.append(f".memory/PLAYBOOKS.md: missing condition, 3–5 steps, or source: {match.group(0)}")

    return errors


def main():
    errors = [f"missing required entry: {name}" for name in REQUIRED if not (ROOT / name).is_file()]
    files = markdown_files(ROOT)
    for path in files:
        errors.extend(check_markdown(ROOT, path))
    errors.extend(check_memory(ROOT))
    memory_files = sorted((ROOT / ".memory").rglob("*.md"))
    if memory_files:
        ignored = subprocess.run(
            ["git", "check-ignore", "--no-index", "--stdin"],
            cwd=ROOT,
            input="\n".join(str(path.relative_to(ROOT)) for path in memory_files) + "\n",
            text=True,
            capture_output=True,
        )
        if ignored.returncode == 0:
            errors.append(f"memory files must not be ignored: {ignored.stdout.strip()}")
        elif ignored.returncode != 1:
            errors.append(f"unable to check memory ignore rules: {ignored.stderr.strip()}")
    if errors:
        print("Documentation checks failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Documentation checks passed: {len(files)} Markdown files; local links and memory contracts checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
