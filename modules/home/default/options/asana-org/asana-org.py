#!/usr/bin/env python3

import argparse
import datetime as dt
import fcntl
import json
import os
import re
import stat
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


API_BASE = "https://app.asana.com/api/1.0"
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
ATTACHMENT_FIELDS = "name,host,download_url,permanent_url,view_url,size"
MAX_ATTACHMENT_BYTES = 25 * 1024 * 1024
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

    def request(self, method, path, params=None, data=None):
        url = API_BASE + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/json",
            "User-Agent": "asana-org/1",
        }
        body = None
        if data is not None:
            headers["Content-Type"] = "application/json"
            body = json.dumps({"data": data}).encode("utf-8")
        request = urllib.request.Request(
            url,
            data=body,
            headers=headers,
            method=method,
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

    def get(self, path, params=None):
        return self.request("GET", path, params)

    def put(self, path, data, params=None):
        return self.request("PUT", path, params, data)

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
        "attachments": [],
    }


def https_url(value):
    parsed = urllib.parse.urlparse(value or "")
    return parsed.scheme == "https" and bool(parsed.netloc)


def attachment_filename(name, gid):
    name = re.sub(r"[/\x00\[\]]", "_", one_line(name))
    if name.strip(".") == "":
        return f"attachment-{gid}"
    path = Path(name)
    suffix = path.suffix if len(path.suffix) <= 16 else ""
    stem = name[: len(name) - len(suffix)]
    while len((stem + suffix).encode("utf-8")) > 200:
        stem = stem[:-1]
    return stem + suffix


def normalize_attachments(raw_attachments, task_gid):
    attachments = []
    filenames = set()
    for raw in raw_attachments:
        if not isinstance(raw, dict):
            raise SyncError(f"Task {task_gid} has an invalid attachment")
        gid = raw.get("gid")
        size = raw.get("size")
        if not isinstance(gid, str) or not gid.isdigit():
            raise SyncError(f"Task {task_gid} has an attachment with an invalid gid")
        if size is not None and (type(size) is not int or size < 0):
            raise SyncError(f"Attachment {gid} has an invalid size")
        name = one_line(optional_string(raw, "name") or "") or f"attachment-{gid}"
        filename = attachment_filename(name, gid)
        if filename in filenames:
            path = Path(filename)
            filename = f"{path.stem}-{gid}{path.suffix}"
        filenames.add(filename)
        host = optional_string(raw, "host") or ""
        download_url = optional_string(raw, "download_url")
        link = optional_string(raw, "permanent_url") or optional_string(raw, "view_url")
        attachments.append(
            {
                "gid": gid,
                "name": name.replace("[", "(").replace("]", ")"),
                "filename": filename,
                "host": host,
                "download_url": download_url if https_url(download_url) else None,
                "link": link if https_url(link) else None,
                "local": host == "asana"
                and https_url(download_url)
                and (size is None or size <= MAX_ATTACHMENT_BYTES),
            }
        )
    return attachments


def attachment_dir(attach_dir, gid):
    # Mirror org-attach-id-uuid-folder-format for the heading's :ID:.
    org_id = f"asana-{gid}"
    return attach_dir / org_id[:2] / org_id[2:]


def download_attachments(task, attach_dir):
    directory = attachment_dir(attach_dir, task["gid"])
    umask = os.umask(0)
    os.umask(umask)
    for attachment in task["attachments"]:
        path = directory / attachment["filename"]
        # Never replace an existing copy; it may hold local edits.
        if not attachment["local"] or path.exists():
            continue
        request = urllib.request.Request(
            attachment["download_url"], headers={"User-Agent": "asana-org/1"}
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                content = response.read(MAX_ATTACHMENT_BYTES + 1)
        except (urllib.error.URLError, OSError) as error:
            # Link it for now; the next sync retries the missing file.
            print(
                f"asana-org: could not download attachment {attachment['gid']}: {error}",
                file=sys.stderr,
            )
            attachment["local"] = False
            continue
        if len(content) > MAX_ATTACHMENT_BYTES:
            attachment["local"] = False
            continue
        directory.mkdir(parents=True, exist_ok=True)
        atomic_write(path, content, 0o666 & ~umask)


def org_date(value, brackets="<>"):
    left, right = brackets
    return f"{left}{value:%Y-%m-%d} {WEEKDAYS[value.weekday()]}{right}"


def render_task(task, status, level):
    project = ", ".join(task["projects"])
    title = f"{project} > {task['name']}" if project else task["name"]
    attachments = task.get("attachments", [])
    if any(attachment["local"] for attachment in attachments):
        title += " :ATTACH:"
    lines = [f"{'*' * level} {status} {title}"]
    if status == "DONE":
        completed = task["completed_datetime"].astimezone()
        lines.append(f"CLOSED: {org_date(completed, '[]')[:-1]} {completed:%H:%M}]")
    if task["due_date"]:
        lines.append(f"DEADLINE: {org_date(task['due_date'])}")
    completed = "true" if task["completed"] else "false"
    lines.extend(
        (
            ":PROPERTIES:",
            f":ID: asana-{task['gid']}",
            f":ASANA_ID: {task['gid']}",
            f":ASANA_COMPLETED: {completed}",
            ":END:",
        )
    )
    if task["projects"]:
        lines.append("Project: " + ", ".join(task["projects"]))
    if task["sections"]:
        lines.append("Section: " + ", ".join(task["sections"]))
    lines.append(f"[[{task['permalink']}][Open in Asana]]")
    notes = task["notes"].strip()
    if notes:
        lines.extend(("", "Description:"))
        lines.extend(f"  {line}" if line else "" for line in notes.splitlines())
    if attachments:
        lines.extend(("", "Attachments:"))
    for attachment in attachments:
        if attachment["local"]:
            lines.append(f"- [[attachment:{attachment['filename']}]]")
        elif attachment["link"]:
            lines.append(f"- [[{attachment['link']}][{attachment['name']}]]")
        else:
            lines.append(f"- {attachment['name']}")
    return "\n".join(lines)


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
        states = re.findall(r"(?m)^:ASANA_COMPLETED:[ \t]*(.*?)[ \t]*\r?$", block)
        if len(states) > 1 or (states and states[0] not in ("true", "false")):
            raise SyncError(f"Managed Asana task {ids[0]} has invalid completion state")
        entries.append(
            {
                "gid": ids[0],
                "status": heading.group(2),
                "synced_completed": (states[0] == "true" if states else None),
                "level": len(heading.group(1)),
                "block": block,
            }
        )
    return entries


def update_retained_block(block, level):
    block = re.sub(r"^\*+ ", "*" * level + " ", block, count=1)
    state = re.search(r"(?m)^:ASANA_COMPLETED:[^\r\n]*\r?$", block)
    if state:
        ending = "\r" if state.group(0).endswith("\r") else ""
        block = (
            block[: state.start()]
            + ":ASANA_COMPLETED: true"
            + ending
            + block[state.end() :]
        )
    else:
        drawer_end = re.search(r"(?m)^:END:\r?$", block)
        if not drawer_end:
            raise SyncError("Managed Asana task has no property drawer end")
        newline = "\r\n" if "\r\n" in block else "\n"
        block = (
            block[: drawer_end.start()]
            + f":ASANA_COMPLETED: true{newline}"
            + block[drawer_end.start() :]
        )
    project = re.search(r"(?m)^Project: (.+)$", block)
    if not project:
        return block
    prefix = project.group(1).rstrip("\r") + " > "
    heading = re.match(r"^\*+ (?:TODO|PROG|EVAL|HOLD|DONE) (.+)", block)
    if not heading:
        raise SyncError("Managed Asana task has an invalid heading")
    if heading.group(1).startswith(prefix):
        return block
    return block[: heading.start(1)] + prefix + block[heading.start(1) :]


def merge_tasks(active, previous, fetch_task, complete_task, task_level):
    active_by_gid = {}
    for task in active:
        if task["completed"]:
            continue
        if task["gid"] in active_by_gid:
            raise SyncError(f"Asana returned duplicate task {task['gid']}")
        active_by_gid[task["gid"]] = task

    remotely_completed = []
    for entry in previous:
        if entry["gid"] in active_by_gid or (
            entry["status"] == "DONE" and entry["synced_completed"] in (True, None)
        ):
            continue
        task = fetch_task(entry["gid"])
        if task is not None and task["completed"]:
            remotely_completed.append(task)

    locally_completed = []
    for entry in previous:
        if (
            entry["gid"] in active_by_gid
            and entry["status"] == "DONE"
            and entry["synced_completed"] in (False,)
        ):
            task = complete_task(entry["gid"])
            if task["gid"] != entry["gid"] or not task["completed"]:
                raise SyncError(f"Asana did not complete task {entry['gid']}")
            locally_completed.append(task)

    completed_ids = {task["gid"] for task in remotely_completed + locally_completed}
    for gid in completed_ids:
        active_by_gid.pop(gid, None)

    active_sorted = sorted(
        active_by_gid.values(),
        key=lambda task: (
            task["due_date"] is None,
            task["due_date"] or dt.date.max,
            task["name"].casefold(),
            task["gid"],
        ),
    )
    newly_completed = remotely_completed + locally_completed
    newly_completed.sort(key=lambda task: task["completed_datetime"], reverse=True)
    retained_done = [
        update_retained_block(entry["block"], task_level)
        for entry in previous
        if entry["status"] == "DONE"
        and entry["gid"] not in active_by_gid
        and entry["gid"] not in completed_ids
        and entry["synced_completed"] in (True, None)
    ]
    blocks = [render_task(task, "TODO", task_level) for task in active_sorted]
    blocks.extend(render_task(task, "DONE", task_level) for task in newly_completed)
    blocks.extend(retained_done)
    return (
        "\n\n".join(blocks),
        len(active_sorted),
        len(newly_completed) + len(retained_done),
        len(locally_completed),
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


def sync(org_file, token_file, workspace, attach_dir):
    token = read_token(token_file)
    org_file = org_file.expanduser()
    try:
        parent = org_file.parent.resolve(strict=True)
    except OSError as error:
        raise SyncError(
            f"Org file directory is unavailable: {org_file.parent}"
        ) from error
    org_file = parent / org_file.name

    runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    lock_path = runtime_dir / f"asana-org-{os.getuid()}.lock"
    with lock_path.open("a", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            file_stat = org_file.stat()
        except FileNotFoundError:
            original = None
            file_mode = 0o600
        else:
            if not stat.S_ISREG(file_stat.st_mode):
                raise SyncError(f"Org path is not a regular file: {org_file}")
            original = org_file.read_bytes()
            file_mode = stat.S_IMODE(file_stat.st_mode)

        try:
            text = original.decode("utf-8") if original is not None else ""
        except UnicodeDecodeError as error:
            raise SyncError(f"Org file is not UTF-8: {org_file}") from error
        previous = parse_entries(text)

        def current_contents():
            try:
                return org_file.read_bytes()
            except FileNotFoundError:
                return None

        asana = Asana(token)

        def with_attachments(task):
            raw_attachments = asana.paginated(
                "/attachments",
                {"parent": task["gid"], "limit": 100, "opt_fields": ATTACHMENT_FIELDS},
            )
            task["attachments"] = normalize_attachments(raw_attachments, task["gid"])
            download_attachments(task, attach_dir)
            return task

        active = [
            with_attachments(task) for task in fetch_active_tasks(asana, workspace)
        ]

        def fetch_task(gid):
            try:
                payload = asana.get(f"/tasks/{gid}", {"opt_fields": TASK_FIELDS})
            except APIError as error:
                if error.status in (403, 404):
                    return None
                raise
            task = normalize_task(payload["data"])
            return with_attachments(task) if task["completed"] else task

        def complete_task(gid):
            if current_contents() != original:
                raise SyncError(
                    "Org file changed during sync; refusing Asana writeback"
                )
            payload = asana.put(
                f"/tasks/{gid}",
                {"completed": True},
                {"opt_fields": TASK_FIELDS},
            )
            return with_attachments(normalize_task(payload["data"]))

        merged, todo_count, done_count, completed_count = merge_tasks(
            active, previous, fetch_task, complete_task, 1
        )
        updated = (merged.rstrip("\r\n") + "\n" if merged else "").encode("utf-8")
        counts = f"{todo_count} TODO, {done_count} DONE"
        if completed_count:
            counts += f", {completed_count} completed in Asana"
        if updated == original:
            print(f"No changes to {org_file} ({counts})")
            return
        if current_contents() != original:
            raise SyncError("Org file changed during sync; refusing to overwrite it")
        atomic_write(org_file, updated, file_mode)
        print(f"Updated {org_file} ({counts})")


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
    old_done = old_done.replace(":ASANA_COMPLETED: true\n", "")
    previous = parse_entries(
        "*** TODO Missing now\n:PROPERTIES:\n:ASANA_ID: 2\n:END:\n\n" + old_done + "\n"
    )

    def unexpected_call(gid):
        raise AssertionError(f"Unexpected callback for task {gid}")

    body, todo_count, done_count, completed_count = merge_tasks(
        [active],
        previous,
        lambda gid: completed if gid == "2" else None,
        unexpected_call,
        3,
    )
    assert todo_count == 1 and done_count == 2 and completed_count == 0
    assert body.index("*** TODO Site > Current task") < body.index(
        "*** DONE Finished task"
    )
    assert body.index("*** DONE Finished task") < body.index(
        "*** DONE Archive > Older task"
    )
    assert "\n  * not a heading\n" in body
    assert "\n  #+title: not a directive" in body
    assert "\n:ID: asana-1\n:ASANA_ID: 1\n" in body
    assert all(entry["synced_completed"] is not None for entry in parse_entries(body))

    completed_active = {
        **active,
        "completed": True,
        "completed_datetime": dt.datetime.fromisoformat("2026-08-26T20:00:00+00:00"),
    }
    local_done = render_task(active, "TODO", 3).replace("*** TODO ", "*** DONE ", 1)
    completion_calls = []

    def complete_active(gid):
        completion_calls.append(gid)
        return completed_active

    completed_body, todo_count, done_count, completed_count = merge_tasks(
        [active],
        parse_entries(local_done),
        unexpected_call,
        complete_active,
        3,
    )
    assert completion_calls == ["1"]
    assert todo_count == 0 and done_count == 1 and completed_count == 1
    assert "*** DONE Site > Current task" in completed_body
    assert ":ASANA_COMPLETED: true" in completed_body

    reopened_body, todo_count, done_count, completed_count = merge_tasks(
        [active],
        parse_entries(completed_body),
        unexpected_call,
        unexpected_call,
        3,
    )
    assert todo_count == 1 and done_count == 0 and completed_count == 0
    assert "*** TODO Site > Current task" in reopened_body
    assert ":ASANA_COMPLETED: false" in reopened_body

    legacy_done = local_done.replace(":ASANA_COMPLETED: false\n", "")
    migrated_body, todo_count, done_count, completed_count = merge_tasks(
        [active],
        parse_entries(legacy_done),
        unexpected_call,
        unexpected_call,
        3,
    )
    assert todo_count == 1 and done_count == 0 and completed_count == 0
    assert "*** TODO Site > Current task" in migrated_body

    retried_body, todo_count, done_count, completed_count = merge_tasks(
        [],
        parse_entries(local_done),
        lambda gid: completed_active,
        unexpected_call,
        3,
    )
    assert todo_count == 0 and done_count == 1 and completed_count == 0
    assert ":ASANA_COMPLETED: true" in retried_body

    def fail_completion(gid):
        raise SyncError(f"Expected failure for task {gid}")

    try:
        merge_tasks(
            [active],
            parse_entries(local_done),
            unexpected_call,
            fail_completion,
            3,
        )
    except SyncError as error:
        assert str(error) == "Expected failure for task 1"
    else:
        raise AssertionError("Completion error did not abort the sync")

    dedicated_body, todo_count, done_count, completed_count = merge_tasks(
        [active],
        parse_entries(body),
        unexpected_call,
        unexpected_call,
        1,
    )
    assert todo_count == 1 and done_count == 2 and completed_count == 0
    assert len(parse_entries(dedicated_body)) == 3
    assert "\n** TODO " not in "\n" + dedicated_body
    assert "\n** DONE " not in "\n" + dedicated_body
    try:
        parse_entries("Unmanaged text\n" + dedicated_body)
    except SyncError as error:
        assert str(error) == "Managed Asana region contains unrecognized content"
    else:
        raise AssertionError("Unmanaged Org content was accepted")

    attachments = normalize_attachments(
        [
            {
                "gid": "10",
                "name": "Report [final].xlsx",
                "host": "asana",
                "download_url": "https://s3.example/report",
                "permanent_url": "https://app.asana.com/app/asana/-/get_asset?asset_id=10",
                "size": 1024,
            },
            {
                "gid": "11",
                "name": "Report [final].xlsx",
                "host": "asana",
                "download_url": "https://s3.example/copy",
                "size": None,
            },
            {
                "gid": "12",
                "name": "Huge.mov",
                "host": "asana",
                "download_url": "https://s3.example/huge",
                "permanent_url": "https://app.asana.com/huge",
                "size": MAX_ATTACHMENT_BYTES + 1,
            },
            {
                "gid": "13",
                "name": "Shared doc",
                "host": "gdrive",
                "download_url": None,
                "view_url": "https://docs.google.com/d/13",
            },
            {"gid": "14", "name": "../..", "host": "asana", "download_url": None},
        ],
        "1",
    )
    assert [attachment["filename"] for attachment in attachments] == [
        "Report _final_.xlsx",
        "Report _final_-11.xlsx",
        "Huge.mov",
        "Shared doc",
        ".._..",
    ]
    assert [attachment["local"] for attachment in attachments] == [
        True,
        True,
        False,
        False,
        False,
    ]
    assert attachment_dir(Path("/a"), "1") == Path("/a/as/ana-1")
    attached = render_task({**active, "attachments": attachments}, "TODO", 1)
    assert attached.startswith("* TODO Site > Current task :ATTACH:\n")
    assert "\n- [[attachment:Report _final_-11.xlsx]]\n" in attached
    assert "\n- [[https://app.asana.com/huge][Huge.mov]]\n" in attached
    assert "\n- [[https://docs.google.com/d/13][Shared doc]]\n" in attached
    assert attached.endswith("\n- ../..")
    retained = update_retained_block(attached.replace("TODO", "DONE", 1), 1)
    assert retained.startswith("* DONE Site > Current task :ATTACH:\n")
    assert (
        ":ATTACH:"
        not in render_task(
            {**active, "attachments": attachments[2:]}, "TODO", 1
        ).splitlines()[0]
    )
    print("self-test passed")


def main():
    parser = argparse.ArgumentParser(
        description="Mirror Asana My Tasks into a dedicated Org file"
    )
    parser.add_argument("--org-file", type=Path)
    parser.add_argument("--token-file", type=Path)
    parser.add_argument("--workspace")
    parser.add_argument("--attach-dir", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if (
        not args.org_file
        or not args.token_file
        or not args.workspace
        or not args.attach_dir
    ):
        parser.error(
            "--org-file, --token-file, --workspace, and --attach-dir are required"
        )
    if not args.workspace.isdigit():
        parser.error("--workspace must be a numeric Asana gid")
    sync(args.org_file, args.token_file, args.workspace, args.attach_dir.expanduser())


if __name__ == "__main__":
    try:
        main()
    except (SyncError, OSError) as error:
        raise SystemExit(f"asana-org: {error}") from error
