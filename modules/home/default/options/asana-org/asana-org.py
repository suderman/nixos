#!/usr/bin/env python3

import argparse
import datetime as dt
import fcntl
import json
import os
import re
import stat
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


API_BASE = "https://app.asana.com/api/1.0"
BEGIN_MARKER = "# asana-org:begin"
END_MARKER = "# asana-org:end"
LEGACY_BEGIN_MARKER = "# asana-to-org:begin"
LEGACY_END_MARKER = "# asana-to-org:end"
TASK_FIELDS = ",".join(
    (
        "gid",
        "name",
        "notes",
        "completed",
        "completed_at",
        "due_on",
        "due_at",
        "permalink_url",
        "memberships.project.name",
        "memberships.section.name",
        "assignee_section.name",
    )
)
WEEKDAYS = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")


class SyncError(Exception):
    pass


class APIError(SyncError):
    def __init__(self, status, path):
        self.status = status
        super().__init__(f"Asana API returned HTTP {status} for {path}")


class Asana:
    def __init__(self, token):
        self.token = token

    def get(self, path, params=None):
        url = API_BASE + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        request = urllib.request.Request(
            url,
            headers={
                "Authorization": f"Bearer {self.token}",
                "Accept": "application/json",
                "User-Agent": "asana-org/1",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                payload = json.load(response)
        except urllib.error.HTTPError as error:
            raise APIError(error.code, path) from error
        except urllib.error.URLError as error:
            raise SyncError(f"Could not reach Asana: {error.reason}") from error
        except (json.JSONDecodeError, UnicodeDecodeError) as error:
            raise SyncError(f"Asana returned invalid JSON for {path}") from error
        if not isinstance(payload, dict) or "data" not in payload:
            raise SyncError(f"Asana returned an invalid response for {path}")
        return payload

    def paginated(self, path, params):
        results = []
        offset = None
        seen_offsets = set()
        while True:
            page_params = dict(params)
            if offset is not None:
                page_params["offset"] = offset
            payload = self.get(path, page_params)
            data = payload["data"]
            if not isinstance(data, list):
                raise SyncError(f"Asana returned invalid paginated data for {path}")
            results.extend(data)
            next_page = payload.get("next_page")
            if next_page is None:
                return results
            if not isinstance(next_page, dict) or not isinstance(
                next_page.get("offset"), str
            ):
                raise SyncError(f"Asana returned invalid pagination for {path}")
            offset = next_page["offset"]
            if offset in seen_offsets:
                raise SyncError(f"Asana repeated a pagination offset for {path}")
            seen_offsets.add(offset)


def one_line(value):
    return " ".join(value.splitlines()).strip()


def optional_string(task, key):
    value = task.get(key)
    if value is None:
        return None
    if not isinstance(value, str):
        raise SyncError(f"Task {task.get('gid', '?')} has invalid {key}")
    return value


def parse_datetime(value, field, gid):
    try:
        parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise SyncError(f"Task {gid} has invalid {field}") from error
    if parsed.utcoffset() is None:
        raise SyncError(f"Task {gid} has timezone-less {field}")
    return parsed


def normalize_task(task):
    if not isinstance(task, dict):
        raise SyncError("Asana returned a non-object task")
    gid = task.get("gid")
    name = task.get("name")
    completed = task.get("completed")
    if not isinstance(gid, str) or not gid.isdigit():
        raise SyncError("Asana returned a task with an invalid gid")
    if not isinstance(name, str) or not one_line(name):
        raise SyncError(f"Task {gid} has an invalid name")
    if not isinstance(completed, bool):
        raise SyncError(f"Task {gid} has an invalid completed value")

    notes = optional_string(task, "notes") or ""
    permalink = optional_string(task, "permalink_url")
    if not permalink:
        raise SyncError(f"Task {gid} has no permalink")
    parsed_url = urllib.parse.urlparse(permalink)
    if parsed_url.scheme != "https" or not parsed_url.netloc:
        raise SyncError(f"Task {gid} has an invalid permalink")

    due_on = optional_string(task, "due_on")
    due_at = optional_string(task, "due_at")
    due_date = None
    if due_on:
        try:
            due_date = dt.date.fromisoformat(due_on)
        except ValueError as error:
            raise SyncError(f"Task {gid} has invalid due_on") from error
    elif due_at:
        due_date = parse_datetime(due_at, "due_at", gid).astimezone().date()

    completed_at = optional_string(task, "completed_at")
    completed_datetime = None
    if completed:
        if not completed_at:
            raise SyncError(f"Completed task {gid} has no completed_at value")
        completed_datetime = parse_datetime(completed_at, "completed_at", gid)

    memberships = task.get("memberships") or []
    if not isinstance(memberships, list):
        raise SyncError(f"Task {gid} has invalid memberships")
    projects = []
    sections = []
    for membership in memberships:
        if not isinstance(membership, dict):
            raise SyncError(f"Task {gid} has an invalid membership")
        for key, output in (("project", projects), ("section", sections)):
            item = membership.get(key)
            if item is None:
                continue
            if not isinstance(item, dict) or not isinstance(item.get("name"), str):
                raise SyncError(f"Task {gid} has an invalid membership {key}")
            value = one_line(item["name"])
            if value and value not in output:
                output.append(value)

    assignee_section = task.get("assignee_section")
    if not sections and assignee_section is not None:
        if not isinstance(assignee_section, dict) or not isinstance(
            assignee_section.get("name"), str
        ):
            raise SyncError(f"Task {gid} has an invalid assignee section")
        section = one_line(assignee_section["name"])
        if section:
            sections.append(section)

    return {
        "gid": gid,
        "name": one_line(name),
        "notes": notes,
        "completed": completed,
        "completed_datetime": completed_datetime,
        "due_date": due_date,
        "permalink": permalink,
        "projects": projects,
        "sections": sections,
    }


def org_date(value, brackets="<>"):
    left, right = brackets
    return f"{left}{value:%Y-%m-%d} {WEEKDAYS[value.weekday()]}{right}"


def render_task(task, status, level):
    project = ", ".join(task["projects"])
    title = f"{project} > {task['name']}" if project else task["name"]
    lines = [f"{'*' * level} {status} {title}"]
    if status == "DONE":
        completed = task["completed_datetime"].astimezone()
        lines.append(f"CLOSED: {org_date(completed, '[]')[:-1]} {completed:%H:%M}]")
    if task["due_date"]:
        lines.append(f"DEADLINE: {org_date(task['due_date'])}")
    lines.extend((":PROPERTIES:", f":ASANA_ID: {task['gid']}", ":END:"))
    if task["projects"]:
        lines.append("Project: " + ", ".join(task["projects"]))
    if task["sections"]:
        lines.append("Section: " + ", ".join(task["sections"]))
    lines.append(f"[[{task['permalink']}][Open in Asana]]")
    notes = task["notes"].strip()
    if notes:
        lines.extend(("", "Description:"))
        lines.extend(f"  {line}" if line else "" for line in notes.splitlines())
    return "\n".join(lines)


def find_managed_region(text):
    marker_pairs = (
        (BEGIN_MARKER, END_MARKER),
        (LEGACY_BEGIN_MARKER, LEGACY_END_MARKER),
    )
    begins = []
    ends = []
    offset = 0
    for line in text.splitlines(keepends=True):
        value = line.rstrip("\r\n")
        for pair_index, (begin, end) in enumerate(marker_pairs):
            if value == begin:
                begins.append((pair_index, offset, offset + len(line)))
            elif value == end:
                ends.append((pair_index, offset, offset + len(line)))
        offset += len(line)

    if not begins and not ends:
        return None
    if (
        len(begins) != 1
        or len(ends) != 1
        or begins[0][0] != ends[0][0]
        or begins[0][1] >= ends[0][1]
    ):
        raise SyncError("Org file contains invalid or duplicate Asana marker pairs")
    if begins[0][2] == begins[0][1] + len(marker_pairs[begins[0][0]][0]):
        raise SyncError("Asana begin marker must end with a newline")
    return {
        "start": begins[0][1],
        "body_start": begins[0][2],
        "body_end": ends[0][1],
        "end": ends[0][2],
        "body": text[begins[0][2] : ends[0][1]],
    }


def find_target_heading(text, path):
    headings = []
    offset = 0
    for line in text.splitlines(keepends=True):
        match = re.fullmatch(r"(\*+) +(.*?)\s*", line.rstrip("\r\n"))
        if match and match.group(2):
            headings.append(
                {
                    "level": len(match.group(1)),
                    "title": match.group(2),
                    "start": offset,
                }
            )
        offset += len(line)

    stack = []
    matches = []
    for index, heading in enumerate(headings):
        while stack and stack[-1]["level"] >= heading["level"]:
            stack.pop()
        stack.append(heading)
        if [item["title"] for item in stack] == path and [
            item["level"] for item in stack
        ] == list(range(1, len(path) + 1)):
            section_end = len(text)
            for later in headings[index + 1 :]:
                if later["level"] <= heading["level"]:
                    section_end = later["start"]
                    break
            matches.append({**heading, "section_end": section_end})

    if len(matches) != 1:
        rendered = " > ".join(path)
        raise SyncError(f"Org file must contain exactly one heading path: {rendered}")
    return matches[0]


def insert_managed_region(text, target, body):
    block = BEGIN_MARKER + "\n"
    if body:
        block += body.rstrip("\r\n") + "\n"
    block += END_MARKER + "\n"
    before = text[: target["section_end"]]
    after = text[target["section_end"] :]
    if before and not before.endswith(("\n", "\r")):
        before += "\n"
    return before + block + after


def parse_entries(body):
    if not body.strip():
        return []
    headings = list(re.finditer(r"(?m)^(\*+) (TODO|PROG|EVAL|HOLD|DONE) .+$", body))
    if not headings or body[: headings[0].start()].strip():
        raise SyncError("Managed Asana region contains unrecognized content")
    entries = []
    seen = set()
    for index, heading in enumerate(headings):
        end = headings[index + 1].start() if index + 1 < len(headings) else len(body)
        block = body[heading.start() : end].strip("\r\n")
        ids = re.findall(r"(?m)^:ASANA_ID:\s+(\d+)\s*$", block)
        if len(ids) != 1:
            raise SyncError("Every managed Asana task must have exactly one ASANA_ID")
        if ids[0] in seen:
            raise SyncError(f"Managed Asana region contains duplicate task {ids[0]}")
        seen.add(ids[0])
        entries.append(
            {
                "gid": ids[0],
                "status": heading.group(2),
                "level": len(heading.group(1)),
                "block": block,
            }
        )
    return entries


def update_retained_block(block, level):
    block = re.sub(r"^\*+ ", "*" * level + " ", block, count=1)
    project = re.search(r"(?m)^Project: (.+)$", block)
    if not project:
        return block
    prefix = project.group(1).rstrip("\r") + " > "
    heading = re.match(r"^\*+ (?:TODO|PROG|EVAL|HOLD|DONE) (.+)", block)
    if heading.group(1).startswith(prefix):
        return block
    return block[: heading.start(1)] + prefix + block[heading.start(1) :]


def merge_tasks(active, previous, fetch_task, task_level):
    active_by_gid = {}
    for task in active:
        if task["completed"]:
            continue
        if task["gid"] in active_by_gid:
            raise SyncError(f"Asana returned duplicate task {task['gid']}")
        active_by_gid[task["gid"]] = task

    newly_completed = []
    for entry in previous:
        if entry["status"] == "DONE" or entry["gid"] in active_by_gid:
            continue
        task = fetch_task(entry["gid"])
        if task is not None and task["completed"]:
            newly_completed.append(task)

    active_sorted = sorted(
        active_by_gid.values(),
        key=lambda task: (
            task["due_date"] is None,
            task["due_date"] or dt.date.max,
            task["name"].casefold(),
            task["gid"],
        ),
    )
    newly_completed.sort(key=lambda task: task["completed_datetime"], reverse=True)
    retained_done = [
        update_retained_block(entry["block"], task_level)
        for entry in previous
        if entry["status"] == "DONE" and entry["gid"] not in active_by_gid
    ]
    blocks = [render_task(task, "TODO", task_level) for task in active_sorted]
    blocks.extend(render_task(task, "DONE", task_level) for task in newly_completed)
    blocks.extend(retained_done)
    return (
        "\n\n".join(blocks),
        len(active_sorted),
        len(newly_completed) + len(retained_done),
    )


def fetch_active_tasks(asana, workspace):
    payload = asana.get("/users/me/user_task_list", {"workspace": workspace})
    task_list = payload["data"]
    if not isinstance(task_list, dict) or not isinstance(task_list.get("gid"), str):
        raise SyncError("Asana returned an invalid user task list")
    raw_tasks = asana.paginated(
        f"/user_task_lists/{task_list['gid']}/tasks",
        {"completed_since": "now", "limit": 100, "opt_fields": TASK_FIELDS},
    )
    return [normalize_task(task) for task in raw_tasks]


def read_token(path):
    try:
        token = path.read_text(encoding="utf-8").strip()
    except OSError as error:
        raise SyncError(f"Could not read Asana token file: {path}") from error
    if not token or any(character.isspace() for character in token):
        raise SyncError("Asana token file must contain one token and no other text")
    return token


def atomic_write(path, content, mode):
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", prefix=f".{path.name}.", dir=path.parent, delete=False
        ) as output:
            temporary = Path(output.name)
            os.fchmod(output.fileno(), mode)
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
        temporary = None
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def sync(org_file, org_heading, token_file, workspace):
    token = read_token(token_file)
    try:
        org_file = org_file.expanduser().resolve(strict=True)
    except OSError as error:
        raise SyncError(f"Org file is unavailable: {org_file}") from error
    file_stat = org_file.stat()
    if not stat.S_ISREG(file_stat.st_mode):
        raise SyncError(f"Org path is not a regular file: {org_file}")

    runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    lock_path = runtime_dir / f"asana-org-{os.getuid()}.lock"
    with lock_path.open("a", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        original = org_file.read_bytes()
        try:
            text = original.decode("utf-8")
        except UnicodeDecodeError as error:
            raise SyncError(f"Org file is not UTF-8: {org_file}") from error
        region = find_managed_region(text)
        if region is None:
            previous = []
            without_region = text
        else:
            previous = parse_entries(region["body"])
            without_region = text[: region["start"]] + text[region["end"] :]
        target = find_target_heading(without_region, org_heading)
        task_level = target["level"] + 1

        asana = Asana(token)
        active = fetch_active_tasks(asana, workspace)

        def fetch_task(gid):
            try:
                payload = asana.get(f"/tasks/{gid}", {"opt_fields": TASK_FIELDS})
            except APIError as error:
                if error.status in (403, 404):
                    return None
                raise
            return normalize_task(payload["data"])

        merged, todo_count, done_count = merge_tasks(
            active, previous, fetch_task, task_level
        )
        updated = insert_managed_region(without_region, target, merged).encode("utf-8")
        if updated == original:
            print(f"No changes to {org_file} ({todo_count} TODO, {done_count} DONE)")
            return
        if org_file.read_bytes() != original:
            raise SyncError("Org file changed during sync; refusing to overwrite it")
        atomic_write(org_file, updated, stat.S_IMODE(file_stat.st_mode))
        print(f"Updated {org_file} ({todo_count} TODO, {done_count} DONE)")


def self_test():
    active = normalize_task(
        {
            "gid": "1",
            "name": "Current task",
            "notes": "First line\n* not a heading\n#+title: not a directive",
            "completed": False,
            "completed_at": None,
            "due_on": "2026-08-28",
            "due_at": None,
            "permalink_url": "https://app.asana.com/0/0/1",
            "memberships": [{"project": {"name": "Site"}, "section": {"name": "Work"}}],
            "assignee_section": None,
        }
    )
    completed = normalize_task(
        {
            "gid": "2",
            "name": "Finished task",
            "notes": "",
            "completed": True,
            "completed_at": "2026-08-26T18:30:00Z",
            "due_on": None,
            "due_at": None,
            "permalink_url": "https://app.asana.com/0/0/2",
            "memberships": [],
            "assignee_section": None,
        }
    )
    old_done = render_task(
        {**completed, "gid": "3", "name": "Older task", "projects": ["Archive"]},
        "DONE",
        3,
    ).replace("*** DONE Archive > Older task", "*** DONE Older task")
    previous = parse_entries(
        "*** TODO Missing now\n:PROPERTIES:\n:ASANA_ID: 2\n:END:\n\n" + old_done + "\n"
    )
    body, todo_count, done_count = merge_tasks(
        [active], previous, lambda gid: completed if gid == "2" else None, 3
    )
    assert todo_count == 1 and done_count == 2
    assert body.index("*** TODO Site > Current task") < body.index(
        "*** DONE Finished task"
    )
    assert body.index("*** DONE Finished task") < body.index(
        "*** DONE Archive > Older task"
    )
    assert "\n  * not a heading\n" in body
    assert "\n  #+title: not a directive" in body
    source = (
        "* Old\n"
        f"{LEGACY_BEGIN_MARKER}\n{body}\n{LEGACY_END_MARKER}\n"
        "* nonfiction\n"
        "** Asana\n"
    )
    region = find_managed_region(source)
    without_region = source[: region["start"]] + source[region["end"] :]
    target = find_target_heading(without_region, ["nonfiction", "Asana"])
    replaced = insert_managed_region(without_region, target, region["body"])
    assert LEGACY_BEGIN_MARKER not in replaced
    assert replaced.index(BEGIN_MARKER) > replaced.index("** Asana")
    migrated = find_managed_region(replaced)
    assert len(parse_entries(migrated["body"])) == 3
    moved_again = replaced[: migrated["start"]] + replaced[migrated["end"] :]
    target = find_target_heading(moved_again, ["nonfiction", "Asana"])
    assert insert_managed_region(moved_again, target, migrated["body"]) == replaced
    print("self-test passed")


def main():
    parser = argparse.ArgumentParser(
        description="Mirror Asana My Tasks into an Org section"
    )
    parser.add_argument("--org-file", type=Path)
    parser.add_argument("--org-heading", action="append")
    parser.add_argument("--token-file", type=Path)
    parser.add_argument("--workspace")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if (
        not args.org_file
        or not args.org_heading
        or not args.token_file
        or not args.workspace
    ):
        parser.error(
            "--org-file, --org-heading, --token-file, and --workspace are required"
        )
    if any(
        not heading.strip() or heading != heading.strip()
        for heading in args.org_heading
    ):
        parser.error("--org-heading values must be non-empty and trimmed")
    if not args.workspace.isdigit():
        parser.error("--workspace must be a numeric Asana gid")
    sync(args.org_file, args.org_heading, args.token_file, args.workspace)


if __name__ == "__main__":
    try:
        main()
    except (SyncError, OSError) as error:
        raise SystemExit(f"asana-org: {error}") from error
