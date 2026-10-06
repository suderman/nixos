"""Synthetic failures only. No real mount, device or notification changes."""

import importlib.util
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "health", Path(__file__).with_name("storage-health.py")
)
assert spec is not None and spec.loader is not None
health = importlib.util.module_from_spec(spec)
spec.loader.exec_module(health)

# PSI parsing, sustained stalls, healthy build bursts, correlation, hysteresis.
assert health.psi("some avg10=99.00\nfull avg10=62.25 avg60=5") == 62.25
state = {}
for second in range(0, 120, 15):
    health.pressure_step(state, second, 70, 0, 0.4, 0)
assert not state.get("pressure")
health.pressure_step(state, 120, 70, 0, 0.4, 0)
assert state["pressure"]
for second in range(135, 435, 15):
    health.pressure_step(state, second, 0, 0, 0.4, 0)
assert state["pressure"]
health.pressure_step(state, 435, 0, 0, 0.4, 0)
assert not state["pressure"]
for io, memory, available, tasks in [
    (35, 0, 0.02, 0),
    (35, 0, 0.4, 25),
    (0, 30, 0.02, 0),
]:
    state = {}
    for second in range(0, 61, 15):
        health.pressure_step(state, second, io, memory, available, tasks)
    assert state["pressure"]
state = {}
health.pressure_step(state, 0, 70, 0, 0.4, 0)
health.pressure_step(state, 500, 70, 0, 0.4, 0)
assert not state.get("pressure")  # Missed samples do not count as dwell.


def volume(name, quarantine=True):
    return {
        "mountPoint": f"/mnt/{name}",
        "mounts": [f"/mnt/{name}", f"/{name}"],
        "devices": [f"/dev/{name}"],
        "quarantine": quarantine,
        "startupGraceSec": 0,
        "units": [
            f"{name}.automount",
            f"mnt-{name}.automount",
            f"{name}.mount",
            f"mnt-{name}.mount",
        ]
        if quarantine
        else [],
        "jobs": [f"btrbk-snapshots-{name}.service", f"btrbk-backups-{name}-0.service"],
        "services": [],
    }


def report(status="mounted", reason="", hard=False, errors=0):
    return {
        "status": status,
        "reason": reason,
        "hard": hard,
        "errors": errors,
        "uuid": "data-uuid",
        "tokens": ["nvme7", "nvme7n1p1"],
        "counters_seen": True,
    }


cfg = {
    "host": "test",
    "desktopUser": None,
    "desktopUID": None,
    "notifyURL": "https://invalid.test/storage",
    "volumes": {"data": volume("data"), "main": volume("main", False)},
}
cfg["volumes"]["data"]["services"] = ["data-consumer.service"]
metadata = {
    "present": True,
    "uuid": "data-uuid",
    "name": "nvme7n1p1",
    "disk": "nvme7n1",
    "controller": "nvme7",
    "controller_state": "live",
    "offline": False,
}
records = {"/mnt/data": {"dev": "0:42", "type": "btrfs", "ro": False}}
device = Path("/sys/fs/btrfs/data-uuid/devinfo/1")
values = {
    str(device / "missing"): "0",
    str(device / "error_stats"): "read_io_errs 0\nwrite_io_errs 0\n",
}


def fake_read(path, limit=1024 * 1024):
    assert not str(path).startswith(("/mnt/", "/data"))
    return values[str(path)]


# Renumbering and udev-based UUID resolution use only tmpfs/sysfs metadata.
with (
    patch.object(
        health.os, "stat", return_value=SimpleNamespace(st_rdev=os.makedev(259, 9))
    ),
    patch.object(
        Path, "resolve", return_value=Path("/sys/devices/nvme/nvme7/nvme7n1/nvme7n1p1")
    ),
    patch.object(Path, "exists", lambda path: str(path).startswith("/sys/dev/block")),
    patch.object(
        health,
        "read",
        side_effect=lambda path, limit=0: (
            "E:ID_FS_UUID=data-uuid\n" if str(path).startswith("/run/udev") else "live"
        ),
    ),
):
    info = health.device_metadata("/dev/data")
    assert info["controller"] == "nvme7" and info["uuid"] == "data-uuid"
with patch.object(health.os, "stat", side_effect=FileNotFoundError):
    assert health.device_metadata("/dev/data") == {"present": False}

# Mounted/unmounted are not failures; lost expected members and RO are hard.
# Historical counters establish a baseline; increments suspend jobs, not mounts.
with (
    patch.object(health, "device_metadata", return_value=metadata),
    patch.object(health, "mount_records", return_value=records),
    patch.object(Path, "glob", return_value=[device]),
    patch.object(health, "read", fake_read),
):
    assert not health.volume_status(cfg["volumes"]["data"], {})["reason"]
    values[str(device / "error_stats")] = "read_io_errs 2\nwrite_io_errs 0\n"
    assert not health.volume_status(cfg["volumes"]["data"], {})["reason"]
    assert health.volume_status(cfg["volumes"]["data"], {"errors_baseline": 0})[
        "reason"
    ]
    assert not health.volume_status(cfg["volumes"]["data"], {"errors_baseline": 0})[
        "hard"
    ]
    assert not health.volume_status(cfg["volumes"]["data"], {"errors_baseline": 2})[
        "reason"
    ]
    records["/mnt/data"]["ro"] = True
    assert health.volume_status(cfg["volumes"]["data"], {})["hard"]
    records["/mnt/data"]["ro"] = False
    metadata["controller_state"] = "dead"
    assert health.volume_status(cfg["volumes"]["data"], {})["hard"]
    metadata["controller_state"] = "live"
    records.clear()
    assert health.volume_status(cfg["volumes"]["data"], {})["status"] == "unmounted"
    pool = volume("pool")
    pool["devices"] = ["/dev/member1", "/dev/member2"]
    with patch.object(
        health, "device_metadata", side_effect=[metadata, {"present": False}]
    ):
        assert health.volume_status(pool, {})["hard"]

# A slow USB enclosure gets a boot-only grace period, not automatic recovery.
with (
    tempfile.TemporaryDirectory() as temporary,
    patch.object(health, "RUN", Path(temporary) / "private"),
    patch.object(health, "PUBLIC", Path(temporary) / "public"),
    patch.object(
        health.subprocess, "run", return_value=SimpleNamespace(returncode=0)
    ) as run,
    patch.object(health, "command", return_value=""),
    patch.object(health.time, "monotonic", return_value=15) as clock,
    patch.object(health, "device_metadata", return_value={"present": False}) as disk,
    patch.object(health, "mount_records", return_value={}) as mounts,
    patch.object(Path, "glob", return_value=[]),
):
    health.RUN.mkdir()
    usb = volume("pool") | {"startupGraceSec": 60}
    usb_cfg = cfg | {"volumes": {"pool": usb}}
    state = {}
    health.check(usb_cfg, state)
    assert state["volumes"]["pool"]["status"] == "waiting for devices"
    assert not state["volumes"]["pool"].get("failure") and not run.called
    # Grace never permits manual rearm of an absent device.
    try:
        health.rearm(usb_cfg, state, "pool")
    except SystemExit:
        pass
    else:
        raise AssertionError("Absent USB device must not rearm during boot grace")
    # Once observed, disappearance latches immediately, even before 60 seconds.
    disk.return_value = metadata
    clock.return_value = 25
    health.check(usb_cfg, state)
    assert state["volumes"]["pool"]["devices_seen"]
    disk.return_value = {"present": False}
    clock.return_value = 30
    health.check(usb_cfg, state)
    assert state["volumes"]["pool"]["contained"]
    # An enclosure that never appears still fails at the boot deadline.
    state = {}
    clock.return_value = 60
    health.check(usb_cfg, state)
    assert state["volumes"]["pool"]["contained"]
    # Grace cannot hide missing mounted devices, read-only mounts or dead controllers.
    clock.return_value = 15
    mounts.return_value = {"/mnt/pool": {"type": "btrfs", "ro": False}}
    assert health.volume_status(usb, {})["hard"]
    mounts.return_value["/mnt/pool"]["ro"] = True
    assert health.volume_status(usb, {})["reason"] == "filesystem read-only"
    mounts.return_value = {}
    disk.return_value = metadata | {"controller_state": "dead"}
    assert health.volume_status(usb, {})["hard"]
    disk.return_value = {"present": False}
    assert health.volume_status(volume("pool"), {})["hard"]

# One filesystem fails: block and stop only its jobs/consumers; no reboot or kill.
# Returning hardware never clears a latch. Manual rearm does not start services.
with (
    tempfile.TemporaryDirectory() as temporary,
    patch.object(health, "RUN", Path(temporary) / "private"),
    patch.object(health, "PUBLIC", Path(temporary) / "public"),
    patch.object(
        health.subprocess, "run", return_value=SimpleNamespace(returncode=0)
    ) as run,
    patch.object(health, "command", return_value=""),
    patch.object(health.time, "monotonic", return_value=100),
):
    health.RUN.mkdir()
    state = {}
    with patch.object(
        health,
        "volume_status",
        side_effect=lambda v, previous: (
            report("unavailable", "device missing", True)
            if v["quarantine"]
            else report()
        ),
    ):
        health.check(cfg, state)
    assert state["volumes"]["data"]["contained"]
    assert not state["volumes"]["main"].get("failure")
    assert (health.RUN / "blocked/data").exists()
    calls = [call.args[0] for call in run.call_args_list]
    assert [
        "systemctl",
        "--no-block",
        "stop",
        *cfg["volumes"]["data"]["jobs"],
        "data-consumer.service",
    ] in calls
    assert ["systemctl", "mask", "--runtime", *cfg["volumes"]["data"]["units"]] in calls
    assert not any(
        "reboot" in call or "kill" in call or "main.mount" in call for call in calls
    )
    run.reset_mock()
    with patch.object(health, "volume_status", return_value=report()):
        health.check(cfg, state)
    assert state["volumes"]["data"]["contained"] and not run.called
    with patch.object(
        health,
        "volume_status",
        return_value=report("unavailable", "device missing", True),
    ):
        try:
            health.rearm(cfg, state, "data")
        except SystemExit:
            pass
        else:
            raise AssertionError("Absent devices must not rearm")
    assert not run.called
    with patch.object(health, "volume_status", return_value=report(errors=2)):
        health.rearm(cfg, state, "data")
    assert not (health.RUN / "blocked/data").exists()
    assert state["volumes"]["data"]["errors_baseline"] == 2
    assert not any(
        "data-consumer.service" in call.args[0] and "start" in call.args[0]
        for call in run.call_args_list
    )
    # Corrected I/O errors suspend jobs while keeping mounted filesystems online.
    state = {}
    run.reset_mock()
    with patch.object(
        health,
        "volume_status",
        side_effect=lambda v, previous: (
            report("degraded", "new errors", False, 3) if v["quarantine"] else report()
        ),
    ):
        health.check(cfg, state)
    assert not state["volumes"]["data"].get("contained")
    assert not any(
        "mask" in call.args[0] and "data.mount" in call.args[0]
        for call in run.call_args_list
    )
    # Unknown device errors alert, but never quarantine unrelated volumes.
    state = {}
    run.reset_mock()
    with (
        patch.object(health, "volume_status", return_value=report()),
        patch.object(
            health, "command", return_value="[99] I/O error, dev sdz, sector 9"
        ),
    ):
        health.check(cfg, state)
    assert state["active"] and not any(
        "mask" in call.args[0] for call in run.call_args_list
    )
    # Controller matching must work after enumeration changes, without nvme7/70 confusion.
    state = {}
    run.reset_mock()
    with (
        patch.object(
            health,
            "volume_status",
            side_effect=lambda v, previous: (
                report()
                if v["quarantine"]
                else report()
                | {"uuid": "main-uuid", "tokens": ["nvme70", "nvme70n1p1"]}
            ),
        ),
        patch.object(
            health,
            "command",
            return_value="[99] BTRFS info (device nvme7n1p1 state EA): forced readonly",
        ),
    ):
        health.check(cfg, state)
    assert state["volumes"]["data"]["contained"]
    assert not state["volumes"]["main"].get("failure")
    assert not any(
        "btrbk-snapshots-main.service" in call.args[0] for call in run.call_args_list
    )

# Failure during containment keeps the hard-failure latch even if metadata
# looks healthy at the next check; main/root mounts must never be masked.
with (
    tempfile.TemporaryDirectory() as temporary,
    patch.object(health, "RUN", Path(temporary) / "private"),
    patch.object(health, "PUBLIC", Path(temporary) / "public"),
    patch.object(health.subprocess, "run", return_value=SimpleNamespace(returncode=0)),
    patch.object(health, "command", return_value=""),
):
    health.RUN.mkdir()
    state = {}
    with (
        patch.object(
            health,
            "volume_status",
            return_value=report("unavailable", "device missing", True),
        ),
        patch.object(
            health, "quarantine", side_effect=subprocess.TimeoutExpired("systemctl", 3)
        ),
    ):
        try:
            health.check(cfg, state)
        except subprocess.TimeoutExpired:
            pass
        else:
            raise AssertionError("Containment failure must fail the check")
    saved = health.load()
    assert saved["volumes"]["data"]["hard_failure"]
    with (
        patch.object(health, "volume_status", return_value=report()),
        patch.object(health, "quarantine") as quarantine,
    ):
        health.check(cfg, saved)
        assert quarantine.call_count == 1
    assert saved["volumes"]["data"]["contained"]
    assert not saved["volumes"]["main"].get("contained")

# Cached space is never collected from an unmounted or quarantined filesystem.
# O_PATH plus mount ID verification handles an idle-unmount race without statvfs.
with (
    tempfile.TemporaryDirectory() as temporary,
    patch.object(health, "RUN", Path(temporary) / "private"),
    patch.object(health, "PUBLIC", Path(temporary) / "public"),
    patch.object(health, "volume_status", return_value=report()),
    patch.object(health, "load", return_value={}),
    patch.object(
        health,
        "mount_records",
        return_value={
            "/mnt/data": {
                "id": "42",
                "dev": "0:42",
                "source": "/dev/nvme7n1p1",
                "type": "btrfs",
                "ro": False,
            }
        },
    ),
    patch.object(health.os, "open", return_value=7) as opened,
    patch.object(health, "read", return_value="mnt_id:\t42\n") as fdinfo,
    patch.object(
        health.os,
        "fstatvfs",
        return_value=SimpleNamespace(f_blocks=100, f_bavail=40, f_frsize=1024),
    ) as statvfs,
    patch.object(health.os, "close"),
):
    health.RUN.mkdir()
    health.sample_space(cfg, "data")
    assert opened.call_args.args[1] == os.O_PATH | os.O_NOFOLLOW
    assert json.loads((health.PUBLIC / "data.json").read_text())["available"] == 40960
    statvfs.reset_mock()
    fdinfo.return_value = "mnt_id:\t99\n"
    health.sample_space(cfg, "data")
    assert not statvfs.called
    opened.reset_mock()
    with patch.object(health, "volume_status", return_value=report("unmounted")):
        health.sample_space(cfg, "data")
    with patch.object(
        health, "load", return_value={"volumes": {"data": {"failure": "latched"}}}
    ):
        health.sample_space(cfg, "data")
    with patch.object(
        health,
        "mount_records",
        return_value={"/mnt/data": {"dev": "0:99", "type": "autofs", "ro": False}},
    ):
        health.sample_space(cfg, "data")
    assert not opened.called
    health.public_status(
        cfg,
        {
            "volumes": {
                "data": {"status": "unavailable", "failure": "lost", "contained": True}
            }
        },
    )
    text = (health.PUBLIC / "status.txt").read_text()
    assert "quarantined" in text and "lost" in text and "last known" in text
    assert "Filesystems" in text and "Used" in text and "Total" in text
    assert "/dev/nvme7n1p1" in text and "/mnt/data" in text and "btrfs" in text
    assert "60.0 KiB" in text and "100.0 KiB" in text and "main" in text
    assert "\033[32m" in text and "\033[90m" in text
    assert "\033[31m" in text and text.startswith("\033[0m")
    (health.PUBLIC / "data.json").write_text("invalid JSON")
    health.public_status(cfg, {})
    assert "space cache invalid" in (health.PUBLIC / "status.txt").read_text()

# Match rust-motd's table, units, alignment and capacity colors using cache only.
with (
    tempfile.TemporaryDirectory() as temporary,
    patch.object(health, "PUBLIC", Path(temporary)),
    patch.object(health.time, "time", return_value=1000),
    patch.object(health.os, "open", side_effect=AssertionError("No mount access")),
    patch.object(health.os, "statvfs", side_effect=AssertionError("No disk probe")),
    patch.object(health.os, "fstatvfs", side_effect=AssertionError("No disk probe")),
    patch.object(health, "mount_records", side_effect=AssertionError("Cache only")),
):
    sample = {
        "sampled": 900,
        "total": 4 * 2**40,
        "available": 3 * 2**40,
        "device": "/dev/sda1",
        "mount": "/mnt/data",
        "type": "btrfs",
    }
    path = health.PUBLIC / "data.json"
    path.write_text(json.dumps(sample))
    healthy = {"volumes": {"data": report(), "main": report("unmounted")}}
    health.public_status(cfg, healthy)
    text = (health.PUBLIC / "status.txt").read_text()
    plain = re.sub(r"\033\[[0-9;]*m", "", text)
    assert "1.0 TiB" in plain and "4.0 TiB" in plain
    stamp = health.time.strftime("%Y-%m-%d %H:%M:%S %Z", health.time.localtime(900))
    assert f"oldest sample: {stamp}" in plain and "space not sampled" in plain
    assert "data: mounted" not in plain and "main: unmounted" in plain
    header, row, bar = plain.splitlines()[:3]
    for column in ["Device", "Mount", "Type", "Used", "Total"]:
        value = {
            "Device": "/dev/sda1",
            "Mount": "/mnt/data",
            "Type": "btrfs",
            "Used": "1.0 TiB",
            "Total": "4.0 TiB",
        }[column]
        assert header.index(column) == row.index(value)
    assert len(bar) == len(row.rstrip()) and bar.startswith("  [")
    width = len(bar) - 4
    assert f"\033[32m{'=' * int(width * 0.25)}\033[90m" in text
    for ratio, color in [(0, 32), (0.76, 33), (0.96, 31), (1, 31)]:
        path.write_text(
            json.dumps(sample | {"available": int(sample["total"] * (1 - ratio))})
        )
        health.public_status(cfg, healthy)
        assert f"\033[{color}m" in (health.PUBLIC / "status.txt").read_text()
    path.write_text(json.dumps(sample | {"sampled": 100}))
    health.public_status(cfg, healthy)
    assert (
        "data: mounted; stale sample from" in (health.PUBLIC / "status.txt").read_text()
    )
    assert "s old" not in (health.PUBLIC / "status.txt").read_text()
    for broken in [{}, {"total": 1}, sample | {"total": 0}, sample | {"available": -1}]:
        path.write_text(json.dumps(broken))
        health.public_status(cfg, healthy)
        assert "space cache invalid" in (health.PUBLIC / "status.txt").read_text()
    path.write_text(json.dumps(sample))
    health.public_status(
        cfg, {"volumes": {"data": report("read-only", "filesystem read-only")}}
    )
    assert "read-only" in (health.PUBLIC / "status.txt").read_text()

# Hub outage retries do not repeat desktop notifications; server-only hosts
# never need a desktop user. ntfy success clears only the message sent.
with (
    tempfile.TemporaryDirectory() as temporary,
    patch.object(health, "RUN", Path(temporary)),
    patch.object(health, "command", return_value="") as local,
    patch.object(
        health.subprocess, "run", return_value=SimpleNamespace(returncode=1)
    ) as remote,
):
    (health.RUN / "pending.txt").write_text("test alert")
    desktop = cfg | {"desktopUser": "test", "desktopUID": 1000}
    health.notify(desktop)
    health.notify(desktop)
    assert local.call_count == 1 and remote.call_count == 2
    remote.return_value.returncode = 0
    health.notify(cfg)
    assert not (health.RUN / "pending.txt").exists()

print("storage-health synthetic checks passed")
