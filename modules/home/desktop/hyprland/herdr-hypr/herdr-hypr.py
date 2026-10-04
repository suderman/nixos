"""Ephemeral Herdr pairing and routing for explicitly owned agent browsers."""

import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path


class Error(Exception):
    pass


def run(*args, env=None, json_output=True):
    result = subprocess.run(args, env=env, capture_output=True, text=True, timeout=5)
    if result.returncode:
        raise Error(
            result.stderr.strip() or result.stdout.strip() or f"{args[0]} failed"
        )
    data = json.loads(result.stdout) if json_output else result.stdout
    if isinstance(data, dict) and "error" in data:
        raise Error(str(data["error"]))
    return data


def herdr(*args, env=None):
    # The metadata CLI returns no JSON on success, unlike inspection commands.
    if args[:2] == ("workspace", "report-metadata"):
        return run("herdr", *args, env=env, json_output=False)
    return run("herdr", *args, env=env)["result"]


def hypr(kind):
    return run("hyprctl", "-j", kind)


def dispatch(expression):
    result = run("hyprctl", "dispatch", expression, json_output=False)
    if result.strip() != "ok":
        raise Error(result.strip())


def socket_key(env):
    socket = Path(
        env.get("HERDR_SOCKET_PATH", str(Path.home() / ".config/herdr/herdr.sock"))
    )
    stat = socket.stat()
    # Socket generation prevents a restarted server from reusing an old browser.
    identity = f"{socket.resolve()}:{stat.st_ino}:{stat.st_ctime_ns}"
    return hashlib.sha256(identity.encode()).hexdigest()[:12], str(socket)


def context():
    if not os.environ.get("HERDR_WORKSPACE_ID"):
        raise Error("run this command inside a Herdr-owned pane")
    wid = os.environ["HERDR_WORKSPACE_ID"]
    if os.environ.get("HERDR_PANE_ID"):
        wid = herdr("pane", "current", "--current")["pane"]["workspace_id"]
    if not re.fullmatch(r"w[A-Za-z0-9]+", wid):
        raise Error("invalid Herdr workspace ID")
    workspace = herdr("workspace", "get", wid)["workspace"]
    key, socket = socket_key(os.environ)
    return workspace, f"chromium-agent-{key}-{wid}", socket


def target(workspace):
    tokens = workspace.get("tokens", {})
    if not isinstance(tokens, dict):
        return None
    value = tokens.get("hypr_workspace", "")
    if not isinstance(value, str) or tokens.get("hypr_instance") != os.environ.get(
        "HYPRLAND_INSTANCE_SIGNATURE"
    ):
        return None
    # Only absolute selectors. Never accept relative, previous, or empty names.
    if re.fullmatch(r"[1-9][0-9]*|(?:name|special):[^\x00-\x1f\x7f]+", value):
        return value
    return None


def selector(workspace):
    name = workspace["name"]
    if name.startswith("special:"):
        return name
    return str(workspace["id"]) if name == str(workspace["id"]) else f"name:{name}"


def move(client, destination):
    dispatch(
        "hl.dsp.window.move({ workspace = "
        + json.dumps(destination, ensure_ascii=False)
        + ", window = "
        + json.dumps("address:" + client["address"])
        + ", follow = false })"
    )


def route(address):
    client = next((c for c in hypr("clients") if c["address"] == address), None)
    if not client:
        return
    owner = re.fullmatch(
        r"chromium-agent-([0-9a-f]{12})-(w[A-Za-z0-9]+)", client["class"]
    )
    if not owner:
        return
    # Chromium clears environ and flattens argv. Its singleton lock retains PID.
    directory = profile(client["class"])
    if browser_pid(directory) != client["pid"]:
        return
    env = os.environ.copy()
    env["HERDR_SOCKET_PATH"] = str((directory / "herdr.sock").readlink())
    key, _ = socket_key(env)
    if owner[1] != key:
        return
    workspace = herdr("workspace", "get", owner[2], env=env)["workspace"]
    destination = target(workspace)
    if destination and selector(client["workspace"]) != destination:
        move(client, destination)
        print(f"herdr-hypr: {client['address']} {owner[2]} -> {destination}")


def profile(owned_class):
    return Path(os.environ["XDG_RUNTIME_DIR"]) / "chromium-agent" / owned_class


def browser_pid(directory):
    lock = (directory / "SingletonLock").readlink().name
    return int(lock.rsplit("-", 1)[1])


def cdp_endpoint(owned_class):
    directory = profile(owned_class)
    # Reject an old port file after the browser exits, even if its port is reused.
    try:
        pid = browser_pid(directory)
        cmdline = Path(f"/proc/{pid}/cmdline").read_bytes().replace(b"\0", b" ")
        if (
            f" --class={owned_class} ".encode() not in cmdline
            or f" --user-data-dir={directory} ".encode() not in cmdline
        ):
            raise Error(
                "owned agent browser is not running; launch chromium-agent first"
            )
        port = (directory / "DevToolsActivePort").read_text().splitlines()[0]
    except (OSError, ValueError, IndexError) as error:
        raise Error(
            f"chromium-agent for {owned_class.rsplit('-', 1)[1]} is not ready; "
            "run herdr-hypr cdp --start"
        ) from error
    if not port.isascii() or not port.isdigit() or not 1 <= int(port) <= 65535:
        raise Error("invalid DevToolsActivePort")
    return f"http://127.0.0.1:{port}"


def start_browser(owned_class):
    try:
        return cdp_endpoint(owned_class)
    except Error:
        pass
    directory = profile(owned_class)
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    log = directory / "launch.log"
    with log.open("w") as output:
        process = subprocess.Popen(
            ["chromium-agent", "--new-window"],
            stdout=output,
            stderr=output,
            start_new_session=True,
        )
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        try:
            return cdp_endpoint(owned_class)
        except Error:
            if process.poll() not in (None, 0):
                break
            time.sleep(0.1)
    raise Error(
        f"owned browser did not start; inspect {log}; no other browser was used"
    )


def main(args):
    command = args[0] if args else "help"
    if command == "devtools":
        endpoint = "http://127.0.0.1:9222"
        if os.environ.get("HERDR_WORKSPACE_ID"):
            _, owned_class, _ = context()
            endpoint = start_browser(owned_class)
        # Keep the existing MCP server and its flags, only select its browser.
        # pi-lens-ignore: B606
        os.execvp(
            "npx",
            [
                "npx",
                "-y",
                "chrome-devtools-mcp@latest",
                f"--browser-url={endpoint}",
                *args[1:],
            ],
        )  # nosec B606
        return
    if command == "route" and len(args) == 2:
        route(args[1])
        return
    if command == "list" and len(args) == 1:
        hypr("activeworkspace")  # Fail clearly when IPC is unavailable.
        snapshot = herdr("api", "snapshot")["snapshot"]
        print("HERDR\tLABEL\tHYPR\tCWD")
        for workspace in snapshot["workspaces"]:
            destination = target(workspace)
            if destination:
                cwd = next(
                    (
                        p.get("foreground_cwd") or p.get("cwd", "")
                        for p in snapshot["panes"]
                        if p["workspace_id"] == workspace["workspace_id"]
                    ),
                    "",
                )
                print(
                    f"{workspace['workspace_id']}\t{workspace['label']}\t{destination}\t{cwd}"
                )
        return
    if command not in ("pair", "unpair", "goto", "cdp", "launch") or (
        command != "launch" and len(args) != 1 and args != ["cdp", "--start"]
    ):
        raise Error(
            "usage: herdr-hypr pair|unpair|goto|list|cdp [--start]|devtools (launch/route are internal)"
        )
    workspace, owned_class, socket = context()
    wid = workspace["workspace_id"]
    if command == "launch":
        if len(args) < 2:
            raise Error("launch requires a browser command")
        directory = profile(owned_class)
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        socket_link = directory / "herdr.sock"
        if not socket_link.is_symlink():
            socket_link.symlink_to(socket)
        os.environ["HERDR_SOCKET_PATH"] = socket
        os.environ["HERDR_WORKSPACE_ID"] = wid
        # Last flags override personal-profile switches from the existing wrapper.
        flags = [
            f"--class={owned_class}",
            f"--user-data-dir={directory}",
            f"--disk-cache-dir={directory}/cache",
            "--profile-directory=Default",
            "--remote-debugging-port=0",
            "--no-first-run",
            "--no-default-browser-check",
        ]
        print(f"{wid}: {owned_class}; inspect CDP with herdr-hypr cdp", file=sys.stderr)
        # pi-lens-ignore: B606
        os.execvp(args[1], args[1:] + flags)  # nosec B606
    if command == "cdp":
        print(
            start_browser(owned_class)
            if "--start" in args
            else cdp_endpoint(owned_class)
        )
        return
    if command == "unpair":
        herdr(
            "workspace",
            "report-metadata",
            wid,
            "--source",
            "user:herdr-hypr",
            "--clear-token",
            "hypr_workspace",
            "--clear-token",
            "hypr_instance",
        )
        print(f'{wid} "{workspace["label"]}" unpaired; windows unchanged')
        return
    hypr("activeworkspace")
    if command == "goto":
        destination = target(workspace)
        if not destination:
            raise Error(f"{wid} is not paired in this Hyprland session")
        dispatch(
            "hl.dsp.focus({ workspace = "
            + json.dumps(destination, ensure_ascii=False)
            + " })"
        )
        return
    destination = selector(hypr("activeworkspace"))
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    if not signature or len(signature) > 80 or len(destination) > 80:
        raise Error(
            "Hyprland session or workspace name cannot fit Herdr token metadata"
        )
    herdr(
        "workspace",
        "report-metadata",
        wid,
        "--source",
        "user:herdr-hypr",
        "--token",
        f"hypr_workspace={destination}",
        "--token",
        f"hypr_instance={signature}",
    )
    for client in hypr("clients"):
        if client["class"] == owned_class:
            move(client, destination)
    print(f'{wid} "{workspace["label"]}" -> Hyprland workspace {destination}')


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except (Error, OSError, KeyError, ValueError, subprocess.TimeoutExpired) as error:
        print(f"herdr-hypr: {error}", file=sys.stderr)
        sys.exit(1)
