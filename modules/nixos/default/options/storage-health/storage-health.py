"""Metadata-only storage guard and cached display after Kit's Oct 3, 2026 incident.

Space sampling is separate, non-overlapping and O_PATH-based. Kernel D-state
waits cannot be made killable by systemd timeouts or cgroup limits.
"""

import fcntl
import json
import math
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

RUN = Path("/run/storage-health")
PUBLIC = Path("/run/storage-health-motd")
ERROR = r"BTRFS.*(error|forced readonly)|nvme.*(controller is down|reset failure|device inaccessible|Disabling device)|I/O error|critical medium error"


def read(path, limit=1024 * 1024):
    try:
        with open(path) as source:
            return source.read(limit)
    except OSError as error:
        return f"unavailable: {error}\n"


def command(args, seconds=3):
    # A userspace bound only; the containing unit prevents accumulating workers.
    try:
        result = subprocess.run(
            args, capture_output=True, text=True, timeout=seconds, check=False
        )
        return result.stdout[-1024 * 1024 :] + result.stderr[-65536:]
    except (OSError, subprocess.TimeoutExpired) as error:
        return f"unavailable: {error}\n"


def load():
    path = RUN / "state.json"
    return json.loads(path.read_text()) if path.exists() else {}


def atomic(path, text):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(text)
    temporary.replace(path)


def save(state):
    atomic(RUN / "state.json", json.dumps(state, indent=2) + "\n")


def psi(text):
    match = re.search(r"^full avg10=([0-9.]+)", text, re.MULTILINE)
    return float(match[1]) if match else 0.0


def pressure_step(state, now, io, memory, available, d_tasks):
    """Dwell and hysteresis; gaps do not count as consecutive bad samples."""
    if now - state.get("sampled", now) > 45:
        state.pop("bad_since", None)
        state.pop("good_since", None)
    state["sampled"] = now
    correlated = (io >= 30 and (available < 0.05 or d_tasks >= 20)) or (
        memory >= 20 and available < 0.05
    )
    if correlated or io >= 60:
        state.setdefault("bad_since", now)
        state.pop("good_since", None)
        if now - state["bad_since"] >= (60 if correlated else 120):
            state["pressure"] = True
    else:
        state.pop("bad_since", None)
        if io < 10 and memory < 5 and available >= 0.05:
            state.setdefault("good_since", now)
            if now - state["good_since"] >= 300:
                state["pressure"] = False
        else:
            state.pop("good_since", None)


def mount_records():
    records = {}
    for line in read("/proc/self/mountinfo").splitlines():
        fields = line.split()
        if len(fields) > 6 and "-" in fields:
            # mountinfo encodes whitespace and backslashes as octal escapes.
            path = re.sub(r"\\([0-7]{3})", lambda m: chr(int(m[1], 8)), fields[4])
            records[path] = {
                "id": fields[0],
                "dev": fields[2],
                "type": fields[fields.index("-") + 1],
                "source": fields[fields.index("-") + 2],
                "ro": "ro" in fields[5].split(",") or "ro" in fields[-1].split(","),
            }
    return records


def device_metadata(device):
    # /dev and /run/udev are tmpfs metadata. No blkid/SMART/ioctl or disk read.
    try:
        stat = os.stat(device)
    except FileNotFoundError:
        return {"present": False}
    number = f"{os.major(stat.st_rdev)}:{os.minor(stat.st_rdev)}"
    metadata = read(Path("/run/udev/data") / f"b{number}")
    uuid = re.search(r"^E:ID_FS_UUID=(.+)$", metadata, re.MULTILINE)
    path = Path("/sys/dev/block") / number
    if not path.exists():
        return {"present": False}
    resolved = path.resolve()
    controller = next(
        (part for part in resolved.parts if re.fullmatch(r"nvme\d+", part)), ""
    )
    disk = resolved.parent.name if (path / "partition").exists() else resolved.name
    status = (
        read(Path("/sys/class/nvme") / controller / "state").strip()
        if controller
        else ""
    )
    scsi = Path("/sys/class/block") / disk / "device/state"
    offline = read(scsi).strip() in ("offline", "deleted") if scsi.exists() else False
    return {
        "present": True,
        "uuid": uuid[1] if uuid else "",
        "name": resolved.name,
        "disk": disk,
        "controller": controller,
        "controller_state": status,
        "offline": offline,
    }


def volume_status(volume, previous):
    devices = [device_metadata(device) for device in volume["devices"]]
    present = [device for device in devices if device["present"]]
    uuid = str(
        next(
            (device["uuid"] for device in present if device["uuid"]),
            previous.get("uuid", ""),
        )
    )
    tokens = [
        token
        for device in present
        for token in [device["name"], device["disk"], device["controller"]]
        if token
    ]
    records = mount_records()
    # Autofs presence is not a mounted backing filesystem.
    mounted = [
        records[path]
        for path in volume["mounts"]
        if path in records and records[path]["type"] != "autofs"
    ]
    errors = 0
    missing = False
    counters_seen = False
    if uuid:
        for device in (Path("/sys/fs/btrfs") / uuid / "devinfo").glob("*"):
            counters_seen = True
            missing |= read(device / "missing").strip() == "1"
            errors += sum(
                int(m)
                for m in re.findall(
                    r"\s(\d+)\s*$", read(device / "error_stats"), re.MULTILINE
                )
            )
    reason = ""
    hard = False
    status = "mounted" if mounted else "unmounted"
    if any(record["ro"] for record in mounted):
        status, reason, hard = "read-only", "filesystem read-only", True
    elif len(present) != len(devices) or missing:
        status = "degraded" if present else "unavailable"
        reason, hard = "expected backing device missing", True
    elif any(
        device["offline"]
        or (device["controller"] and device["controller_state"] != "live")
        for device in present
    ):
        status, reason, hard = "unavailable", "backing controller not live", True
    elif errors > previous.get("errors_baseline", errors):
        status, reason = "degraded", f"Btrfs device errors={errors}"
    return {
        "status": status,
        "reason": reason,
        "hard": hard,
        "errors": errors,
        "uuid": uuid,
        "tokens": tokens or previous.get("tokens", []),
        "counters_seen": counters_seen,
    }


def quarantine(volume):
    # No lazy/force unmount, writable remount, reset, or random process kill.
    subprocess.run(
        ["systemctl", "mask", "--runtime", *volume["units"]], check=True, timeout=3
    )
    subprocess.run(
        ["systemctl", "--no-block", "stop", *volume["units"]], check=True, timeout=3
    )


def emit(cfg, state, message, capture=True):
    stamp = time.strftime("%Y%m%dT%H%M%S")
    bundle = (
        str(RUN / f"incident-{stamp}") if capture else state.get("bundle", str(RUN))
    )
    text = f"{cfg['host']} storage health: {message}. Diagnostics: {bundle}"
    print(text, flush=True)
    if capture:
        state["bundle"] = bundle
        atomic(RUN / "capture.json", json.dumps({"bundle": bundle, "message": text}))
        subprocess.run(
            ["systemctl", "--no-block", "start", "storage-health-capture.service"],
            check=True,
            timeout=3,
        )
    atomic(RUN / "pending.txt", text)
    state["notify_after"] = 0


def capacity(value):
    for unit in ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]:
        if value < 1024 or unit == "PiB":
            return f"{value:.1f} {unit}"
        value /= 1024


def public_status(cfg, state):
    header = ["Filesystems", "Device", "Mount", "Type", "Used", "Total"]
    entries, warnings, timestamps = [], [], []
    for name, policy in cfg["volumes"].items():
        volume = state.get("volumes", {}).get(name, {})
        status = volume.get("status", "not checked")
        if volume.get("failure"):
            status += "/quarantined" if volume.get("contained") else "/jobs suspended"
        sample = None
        space = "space not sampled"
        path = PUBLIC / f"{name}.json"
        if path.exists():
            try:
                cached = json.loads(path.read_text())
                valid = all(
                    isinstance(cached[key], (int, float)) and math.isfinite(cached[key])
                    for key in ["total", "available", "sampled"]
                )
                if (
                    not valid
                    or not 0 <= cached["available"] <= cached["total"]
                    or cached["total"] <= 0
                ):
                    raise ValueError("Invalid capacity")
                sample = cached
            except (OSError, ValueError, KeyError, TypeError):
                # Broken display cache must not disable storage failure detection.
                space = "space cache invalid"
        used, total, ratio = "?", "?", None
        device = policy["devices"][0]
        mount, kind = policy["mountPoint"], policy.get("fsType", "?")
        if sample:
            total = capacity(sample["total"])
            used = capacity(sample["total"] - sample["available"])
            ratio = (sample["total"] - sample["available"]) / sample["total"]
            device = sample.get("device", device)
            mount, kind = sample.get("mount", mount), sample.get("type", kind)
            timestamps.append(sample["sampled"])
            stamp = time.strftime(
                "%Y-%m-%d %H:%M:%S %Z", time.localtime(sample["sampled"])
            )
            space = f"last known sample: {stamp}"
            # Two missed five-minute samples warrant a visible stale warning.
            if time.time() - sample["sampled"] > 600:
                space = f"stale sample from {stamp}"
        if len(device) > 26:
            device = device[:25] + "…"
        entries.append(([f"  {name}", device, mount, kind, used, total], ratio))
        if status != "mounted" or sample is None or space.startswith("stale"):
            reason = volume.get("failure") or volume.get("reason")
            detail = f"; {reason}" if reason else ""
            color = (
                31
                if volume.get("failure")
                or status in ["read-only", "unavailable", "degraded"]
                else 33
            )
            warnings.append(f"  \033[{color}m{name}: {status}{detail}; {space}\033[0m")
    widths = [
        max(len(row[i]) for row in [header] + [entry[0] for entry in entries])
        for i in range(6)
    ]
    # Match rust-motd's two-space columns and bars spanning the indented rows.
    bar_width = sum(widths) + 8 - 2
    lines = [
        "\033[0m"
        + "  ".join(
            item.ljust(width) for item, width in zip(header, widths, strict=True)
        )
    ]
    for row, ratio in entries:
        lines.append(
            "  ".join(
                item.ljust(width) for item, width in zip(row, widths, strict=True)
            )
        )
        if ratio is not None:
            full = int(bar_width * ratio)
            percent = int(ratio * 100)
            color = 32 if percent <= 75 else 33 if percent <= 95 else 31
            lines.append(
                f"  [\033[{color}m{'=' * full}\033[90m{'=' * (bar_width - full)}\033[0m]"
            )
    if timestamps:
        stamp = time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(min(timestamps)))
        lines.append(f"\033[90mStorage cached; oldest sample: {stamp}\033[0m")
    lines.extend(warnings)
    PUBLIC.mkdir(mode=0o755, exist_ok=True)
    atomic(PUBLIC / "status.txt", "\n".join(lines) + "\n")
    (PUBLIC / "status.txt").chmod(0o644)


def sample_space(cfg, name):
    volume = cfg["volumes"][name]
    state = load().get("volumes", {}).get(name, {})
    if state.get("failure"):
        return
    report = volume_status(volume, state)
    records = mount_records()
    path = next(
        (
            path
            for path in [volume["mountPoint"]] + volume["mounts"]
            if path in records and records[path]["type"] != "autofs"
        ),
        None,
    )
    if report["reason"] or report["status"] != "mounted" or path is None:
        return
    record = records[path]
    # open(2): O_PATH on an untriggered automount returns its autofs directory
    # without triggering it. Compare the descriptor mount ID before fstatvfs:
    # st_dev is not reliable here because Btrfs assigns subvolume device numbers.
    fd = os.open(path, os.O_PATH | os.O_NOFOLLOW)
    try:
        info = read(f"/proc/self/fdinfo/{fd}", 4096)
        match = re.search(r"^mnt_id:\s+(\d+)$", info, re.MULTILINE)
        if not match or match[1] != record["id"]:
            return
        space = os.fstatvfs(fd)
        if (RUN / "blocked" / name).exists():
            return
        PUBLIC.mkdir(mode=0o755, exist_ok=True)
        path = PUBLIC / f"{name}.json"
        atomic(
            path,
            json.dumps(
                {
                    "sampled": time.time(),
                    "total": space.f_blocks * space.f_frsize,
                    "available": space.f_bavail * space.f_frsize,
                    "device": record["source"],
                    "mount": volume["mountPoint"],
                    "type": record["type"],
                }
            ),
        )
        path.chmod(0o644)
    finally:
        os.close(fd)


def check(cfg, state):
    now = time.monotonic()
    journal = command(
        [
            "journalctl",
            "-k",
            "-b",
            "--since=-45seconds",
            "-n",
            "200",
            "--no-pager",
            "-o",
            "short-monotonic",
            "--grep",
            ERROR,
        ],
        2,
    )
    events = [line for line in journal.splitlines() if re.search(ERROR, line)]
    fresh = [line for line in events if line not in state.get("seen", [])]
    state["seen"] = events
    if fresh:
        state["last_error"] = now
    changes = []
    for name, volume in cfg["volumes"].items():
        previous = state.setdefault("volumes", {}).setdefault(name, {})
        report = volume_status(volume, previous)
        matching = [
            line
            for line in fresh
            if any(
                re.search(rf"\b{re.escape(token)}\b", line)
                for token in report["tokens"] + [report["uuid"]]
                if token
            )
        ]
        if matching:
            report["reason"] = report["reason"] or "kernel storage error"
            report["hard"] |= any(
                re.search(
                    r"forced readonly|controller is down|reset failure|device inaccessible|Disabling device",
                    line,
                )
                for line in matching
            )
            report["status"] = "unavailable" if report["hard"] else "degraded"
        previous.update(report)
        if report["hard"]:
            previous["hard_failure"] = True
        if report["counters_seen"]:
            previous.setdefault("errors_baseline", report["errors"])
        if report["reason"] and not previous.get("failure"):
            previous["failure"] = report["reason"]
            (RUN / "blocked").mkdir(mode=0o700, exist_ok=True)
            (RUN / "blocked" / name).touch()
            save(state)  # Retry failed actions next tick without losing the latch.
        if previous.get("failure"):
            if report["hard"] and report["reason"]:
                previous["failure"] = report["reason"]
            if not previous.get("stopped"):
                dependents = volume["jobs"] + volume["services"]
                if dependents:
                    subprocess.run(
                        ["systemctl", "--no-block", "stop", *dependents],
                        check=True,
                        timeout=3,
                    )
                previous["stopped"] = True
            if (
                previous.get("hard_failure")
                and volume["quarantine"]
                and not previous.get("contained")
            ):
                quarantine(volume)
                previous["contained"] = True
            phase = "quarantined" if previous.get("contained") else "jobs suspended"
            if previous.get("announced") != phase:
                changes.append(f"{name}: {previous['failure']}; {phase}")
                previous["announced"] = phase
    mem = dict(re.findall(r"^(\w+):\s+(\d+)", read("/proc/meminfo"), re.MULTILINE))
    available = int(mem["MemAvailable"]) / int(mem["MemTotal"])
    io = psi(read("/proc/pressure/io"))
    memory = psi(read("/proc/pressure/memory"))
    d_tasks = sum(
        read(task, 4096).rsplit(") ", 1)[-1].startswith("D ")
        for task in Path("/proc").glob("[0-9]*/task/[0-9]*/stat")
    )
    old_pressure = bool(state.get("pressure"))
    pressure_step(state, now, io, memory, available, d_tasks)
    state["sample"] = {
        "io_full": io,
        "memory_full": memory,
        "available_fraction": available,
        "d_tasks": d_tasks,
    }
    active = bool(
        any(v.get("failure") for v in state.get("volumes", {}).values())
        or state.get("pressure")
        or now - state.get("last_error", -1000) < 300
    )
    if state.get("pressure") and not old_pressure:
        changes.append("sustained severe pressure")
    if changes or (active and not state.get("active")):
        emit(
            cfg,
            state,
            "; ".join(
                changes
                + [f"I/O full PSI {io:.1f}%, memory full PSI {memory:.1f}%"]
                + ([fresh[-1][-400:]] if fresh else [])
            ),
        )
    elif state.get("active") and not active:
        emit(
            cfg,
            state,
            "pressure/storage-error alarm cleared; no automatic remount or reboot",
            capture=False,
        )
    elif old_pressure and not state.get("pressure"):
        emit(
            cfg,
            state,
            "pressure recovered; filesystem latches still require manual rearm",
            capture=False,
        )
    state["active"] = active
    public_status(cfg, state)
    if (RUN / "pending.txt").exists() and now >= state.get("notify_after", 0):
        subprocess.run(
            ["systemctl", "--no-block", "start", "storage-health-notify.service"],
            check=True,
            timeout=3,
        )
        state["notify_after"] = now + 300


def capture(cfg):
    request = json.loads((RUN / "capture.json").read_text())
    bundles = sorted(RUN.glob("incident-*"))
    for old in bundles[:-2]:
        shutil.rmtree(old)
    bundle = Path(request["bundle"])
    bundle.mkdir(mode=0o700, exist_ok=True)
    (bundle / "reason.txt").write_text(request["message"] + "\n")
    (bundle / "state.json").write_text(read(RUN / "state.json"))
    # Most useful evidence first, before any command that might talk to a driver.
    for source in [
        "meminfo",
        "vmstat",
        "swaps",
        "slabinfo",
        "buddyinfo",
        "pagetypeinfo",
        "zoneinfo",
        "uptime",
        "version",
        "cmdline",
        "self/mountinfo",
        "pressure/cpu",
        "pressure/io",
        "pressure/memory",
    ]:
        (bundle / source.replace("/", "-")).write_text(read(Path("/proc") / source))
    # Direct driver page allocations do not have to appear in RSS or slab.
    # The bad boot attributed ~57.5 GiB to nvidia/nv-vm.c:538 here.
    (bundle / "allocinfo").write_text(read("/proc/allocinfo", 16 * 1024 * 1024))
    with (bundle / "cgroups.txt").open("w") as output:
        roots = [Path("/sys/fs/cgroup")]
        roots += list(roots[0].glob("*.slice"))
        roots += list(Path("/sys/fs/cgroup/system.slice").glob("*.service"))[:150]
        roots += list(Path("/sys/fs/cgroup/user.slice").glob("user-*.slice"))[:20]
        for root in roots:
            output.write(f"\n{root}\n")
            for name in [
                "memory.current",
                "memory.stat",
                "memory.events",
                "memory.swap.current",
                "memory.pressure",
                "io.pressure",
            ]:
                output.write(f"{name}:\n{read(root / name, 32768)}")
    with (bundle / "device-metadata.txt").open("w") as output:
        paths = list(Path("/sys/class/nvme").glob("nvme*/state"))
        for name in ["serial", "model", "firmware_rev"]:
            paths += list(Path("/sys/class/nvme").glob(f"nvme*/{name}"))
        paths += list(Path("/sys/fs/btrfs").glob("*/devinfo/*/error_stats"))
        paths += list(Path("/sys/fs/btrfs").glob("*/devinfo/*/missing"))
        paths += list(Path("/proc/driver/nvidia/gpus").glob("*/information"))
        for path in paths:
            output.write(f"{path}:\n{read(path, 16384)}")
    for name, args in {
        "threads.txt": [
            "ps",
            "-eLo",
            "pid,tid,ppid,stat,rss,vsz,wchan:32,comm",
            "--sort=-rss",
        ],
        "vmstat.txt": ["vmstat", "1", "3"],
        "kernel.txt": ["journalctl", "-k", "-b", "-n", "1000", "--no-pager"],
        "units.txt": ["systemctl", "list-jobs", "--no-pager"],
        "block.txt": ["lsblk", "--nodeps", "-o", "NAME,MAJ:MIN,SIZE,RO,TYPE"],
    }.items():
        (bundle / name).write_text(command(args, 4))
    # smaps_rollup supplies PSS for the 20 largest RSS processes, not every task.
    processes = []
    for path in Path("/proc").glob("[0-9]*/status"):
        match = re.search(r"^VmRSS:\s+(\d+)", read(path, 16384), re.MULTILINE)
        if match:
            processes.append((int(match[1]), path.parent))
    with (bundle / "pss.txt").open("w") as output:
        for _, path in sorted(processes, reverse=True)[:20]:
            output.write(
                f"\n{path}\n{read(path / 'comm', 4096)}{read(path / 'smaps_rollup', 16384)}"
            )
    (bundle / "complete.txt").write_text("proc/sysfs and userspace capture completed\n")
    # Last and bounded by timeout and the collector unit. A wedged GPU must not
    # prevent the proc accounting bundle above from being saved.
    (bundle / "nvidia.txt").write_text(
        command(["/run/current-system/sw/bin/nvidia-smi"], 3)
    )


def notify(cfg):
    path = RUN / "pending.txt"
    if not path.exists():
        return
    message = path.read_text()
    # Local notification can still work without hub/network. Retry only ntfy.
    delivered = RUN / "desktop-message.txt"
    if cfg["desktopUser"] is not None and (
        not delivered.exists() or delivered.read_text() != message
    ):
        command(
            [
                "runuser",
                "-u",
                cfg["desktopUser"],
                "--",
                "env",
                f"DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{cfg['desktopUID']}/bus",
                "notify-send",
                "--urgency=critical",
                "--expire-time=30000",
                f"{cfg['host']} storage health",
                message,
            ],
            3,
        )
        atomic(delivered, message)
    result = subprocess.run(
        [
            "curl",
            "--fail",
            "--silent",
            "--show-error",
            "--connect-timeout",
            "3",
            "--max-time",
            "8",
            "-H",
            f"Title: {cfg['host']} storage health",
            "-H",
            "Priority: high",
            "--data-binary",
            message,
            cfg["notifyURL"],
        ],
        timeout=10,
        check=False,
    )
    if result.returncode == 0 and path.exists() and path.read_text() == message:
        path.unlink()


def rearm(cfg, state, name):
    volume = cfg["volumes"][name]
    previous = state.setdefault("volumes", {}).setdefault(name, {})
    acknowledged = previous.copy()
    acknowledged["errors_baseline"] = 2**63
    report = volume_status(volume, acknowledged)
    if report["reason"]:
        sys.exit(f"Not rearming {name}: {report['reason']}")
    if previous.get("contained"):
        subprocess.run(
            ["systemctl", "unmask", "--runtime", *volume["units"]],
            check=True,
            timeout=3,
        )
        autos = [unit for unit in volume["units"] if unit.endswith(".automount")]
        if autos:
            subprocess.run(
                ["systemctl", "--no-block", "start", *autos], check=True, timeout=3
            )
    (RUN / "blocked" / name).unlink(missing_ok=True)
    previous.clear()
    previous.update(report)
    previous["errors_baseline"] = report["errors"]
    emit(
        cfg,
        state,
        f"{name} manually rearmed; dependent jobs resume on their schedule",
        capture=False,
    )
    public_status(cfg, state)


def main():
    cfg = json.loads(Path(sys.argv[1]).read_text())
    action = sys.argv[2]
    if action == "status" and os.geteuid() != 0:
        print(read(PUBLIC / "status.txt"), end="")
        return
    if os.geteuid() != 0:
        sys.exit("Run storage-health with sudo.")
    RUN.mkdir(mode=0o700, exist_ok=True)
    os.umask(0o077)
    if action == "capture":
        capture(cfg)
    elif action == "notify":
        notify(cfg)
    elif action == "sample":
        sample_space(cfg, sys.argv[3])  # Never hold detector lock during statvfs.
    else:
        with (RUN / "lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            state = load()
            if action == "check":
                check(cfg, state)
            elif action == "status":
                print(json.dumps(state, indent=2))
            elif action == "rearm":
                rearm(cfg, state, sys.argv[3])
            else:
                sys.exit(
                    "Usage: storage-health check|status|capture|notify|sample NAME|rearm NAME"
                )
            save(state)


if __name__ == "__main__":
    main()
