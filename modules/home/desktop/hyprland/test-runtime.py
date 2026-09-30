#!/usr/bin/env python3
"""Run against Sim's hyprctl wrapper, never the physical desktop.

Usage: python3 test-runtime.py /path/to/sim-hyprctl-wrapper
The wrapper must forward all arguments to hyprctl inside Sim as the desktop user.
"""

import argparse
import json
import os
import socket
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--qemu-monitor", help="Sim's optional QEMU HMP socket")
parser.add_argument("ctl", nargs=argparse.REMAINDER, help="Sim hyprctl wrapper")
args = parser.parse_args()
ctl = args.ctl
if not ctl:
    parser.error("Sim hyprctl wrapper required")


def command(*args):
    result = subprocess.run([*ctl, *args], text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stdout.strip() + "\n" + result.stderr.strip())
    return result.stdout


def evaluate(lua):
    return command("eval", lua)


def dispatch(lua):
    return command("dispatch", lua)


def query(name):
    return json.loads(command("-j", name))


def wait_for(predicate):
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError("Timed out waiting for compositor state")


def clean_config():
    assert not any(query("configerrors")), "Compositor reports configuration errors"


evaluate(
    'assert(require("generated.host").name == "sim", "Runtime tests only run on sim")'
)
clean_config()
assert not query("locked")["locked"], (
    "Sim is locked; stop guest hypridle and unlock first"
)
has_hyprbars = "Plugin hyprbars " in command("plugin", "list")


def check_hyprbars():
    if has_hyprbars:
        option = json.loads(command("-j", "getoption", "plugin:hyprbars:bar_height"))
        assert option["set"] and option["int"] == 25, (
            "Hyprbars kept defaults instead of applying feature settings"
        )
        evaluate("assert(hl.plugin.hyprbars.add_button)")


def check_keyboard():
    if not args.qemu_monitor:
        return
    evaluate('require("lib.util").set_layout("dwindle")')
    for keys, layout in [("meta_l-slash", "master"), ("meta_l-alt-slash", "dwindle")]:
        with socket.socket(socket.AF_UNIX) as monitor:
            monitor.settimeout(2)
            monitor.connect(args.qemu_monitor)

            def read_prompt():
                reply = b""
                while not reply.endswith(b"(qemu) "):
                    chunk = monitor.recv(4096)
                    if not chunk:
                        raise RuntimeError("QEMU closed monitor socket")
                    reply += chunk

            read_prompt()
            monitor.sendall(f"sendkey {keys} 100\n".encode())
            read_prompt()
        wait_for(
            lambda layout=layout: query("activeworkspace")["tiledLayout"] == layout
        )


check_hyprbars()
classes = [f"SimHyprTest{os.getpid()}Tiled", f"SimHyprTest{os.getpid()}Float"]
tiled, floating = classes
workspace = f"sim-regression-{os.getpid()}"
capture_layout_binds = """
    local bind = hl.bind
    sim_layout_binds = {}
    hl.bind = function(keys, callback)
        if keys == "SUPER + SLASH" or keys == "SUPER + ALT + SLASH" then
            sim_layout_binds[keys] = callback
        end
    end
    require("binds.main").apply()
    hl.bind = bind
    assert(sim_layout_binds["SUPER + SLASH"])
"""

try:
    evaluate(
        'local ws = hl.get_active_special_workspace(); if ws then hl.dispatch(hl.dsp.workspace.toggle_special((ws.addressable_name or ws.config_name):gsub("^special:", ""))) end'
    )
    dispatch(f'hl.dsp.focus({{workspace="name:{workspace}"}})')
    for cls in classes:
        dispatch(f'hl.dsp.exec_cmd("kitty --class {cls} --title {cls} sleep 10000")')
    wait_for(lambda: len([w for w in query("clients") if w["class"] in classes]) == 2)
    evaluate(capture_layout_binds)
    for selector in ["8", f"name:{workspace}"]:
        dispatch(f'hl.dsp.focus({{workspace="{selector}"}})')
        evaluate('require("lib.util").set_layout("dwindle")')
        for layout in ["master", "scrolling", "monocle", "dwindle"]:
            evaluate('sim_layout_binds["SUPER + SLASH"]()')
            evaluate(
                f'assert(require("lib.util").active_workspace().tiled_layout == "{layout}")'
            )
        evaluate('sim_layout_binds["SUPER + ALT + SLASH"]()')
        evaluate(
            'assert(require("lib.util").active_workspace().tiled_layout == "monocle")'
        )
    check_keyboard()
    if args.qemu_monitor:
        print("QEMU keyboard layout bindings: passed")
    print("numbered/named layout bind callbacks: passed")

    dispatch(
        f'hl.dsp.window.move({{workspace="special:{workspace}", window="class:{floating}"}})'
    )
    evaluate(
        'assert(hl.get_active_special_workspace()); require("lib.util").set_layout("dwindle")'
    )
    evaluate('sim_layout_binds["SUPER + SLASH"]()')
    evaluate('assert(hl.get_active_special_workspace().tiled_layout == "master")')
    dispatch(
        f'hl.dsp.window.move({{workspace="name:{workspace}", window="class:{floating}"}})'
    )
    dispatch(f'hl.dsp.focus({{workspace="name:{workspace}"}})')
    print("visible special-workspace layout: passed")

    dispatch(f'hl.dsp.window.float({{window="class:{floating}", action="float"}})')
    dispatch(f'hl.dsp.focus({{window="class:{tiled}"}})')
    evaluate('require("lib.util").toggle_fullscreen_or_hidden()')
    assert next(w for w in query("clients") if w["class"] == floating)["workspace"][
        "name"
    ].startswith("special:hidden")
    assert query("activewindow")["class"] == tiled
    evaluate('require("lib.util").toggle_fullscreen_or_hidden()')
    assert (
        next(w for w in query("clients") if w["class"] == floating)["workspace"]["name"]
        == workspace
    )
    for mode in ["maximized", "fullscreen"]:
        dispatch(f'hl.dsp.window.fullscreen({{mode="{mode}", action="set"}})')
        evaluate(
            'require("lib.util").toggle_fullscreen_or_hidden(); assert(hl.get_active_window().fullscreen == 0)'
        )
    print("floating scratch space, tiled focus, fullscreen: passed")

    evaluate('require("lib.util").set_layout("dwindle")')
    dispatch(f'hl.dsp.window.float({{window="class:{floating}", action="tile"}})')
    dispatch(f'hl.dsp.focus({{window="class:{tiled}"}})')
    dispatch("hl.dsp.group.toggle()")
    dispatch(f'hl.dsp.focus({{window="class:{floating}"}})')
    dispatch("hl.dsp.group.toggle()")
    dispatch('hl.dsp.window.move({into_group="l"})')
    assert len(query("activewindow")["grouped"]) == 2
    dispatch("hl.dsp.group.next()")
    print("group creation and navigation: passed")

    count = len(query("binds"))
    for _ in range(5):
        command("reload")
        clean_config()
        check_hyprbars()
        assert len(query("binds")) == count, "Reload duplicated or lost bindings"
        evaluate(capture_layout_binds)
        evaluate('require("lib.util").set_layout("master")')
        evaluate('sim_layout_binds["SUPER + SLASH"]()')
        evaluate(
            'assert(require("lib.util").active_workspace().tiled_layout == "scrolling")'
        )
        check_keyboard()
    print(f"five reloads, stable {count} bindings, post-reload cycling: passed")
finally:
    for window in query("clients"):
        if window["class"] in classes:
            dispatch(f'hl.dsp.window.close({{window="address:{window["address"]}"}})')
    command("reload")
