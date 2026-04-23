#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json


DESKTOP_INPUTS = {
    "home-manager",
    "stylix",
    "hyprland",
    "hyprland-plugins",
    "nix-flatpak",
}

SIM_INPUTS = {
    "hardware",
}

ISO_INPUTS = {
    "disko",
}


def infer_host(paths: list[str], inputs: list[str]) -> tuple[str, str, list[str]]:
    evidence: list[str] = []

    normalized_paths = [
        path.removeprefix("./").removeprefix("/") for path in paths if path
    ]
    normalized_inputs = [name.strip() for name in inputs if name]

    for path in normalized_paths:
        if path.startswith("hosts/iso/"):
            evidence.append(f"path:{path}")
            return "iso", "installer or ISO-specific path changed", evidence

    for path in normalized_paths:
        if path.startswith("hosts/sim/") or path.startswith("modules/nixos/hardware/"):
            evidence.append(f"path:{path}")
            return "sim", "simulation or hardware-specific path changed", evidence

    for path in normalized_paths:
        if (
            path.startswith("modules/home/desktop/")
            or path.startswith("modules/nixos/desktop/")
            or "/users/" in path
        ):
            evidence.append(f"path:{path}")
            return "cog", "desktop or home-manager path changed", evidence

    for name in normalized_inputs:
        if name in ISO_INPUTS:
            evidence.append(f"input:{name}")
            return "iso", "installer-related flake input changed", evidence

    for name in normalized_inputs:
        if name in SIM_INPUTS:
            evidence.append(f"input:{name}")
            return "sim", "hardware-oriented flake input changed", evidence

    for name in normalized_inputs:
        if name in DESKTOP_INPUTS:
            evidence.append(f"input:{name}")
            return "cog", "desktop-oriented flake input changed", evidence

    if normalized_paths:
        evidence.extend(f"path:{path}" for path in normalized_paths)
    if normalized_inputs:
        evidence.extend(f"input:{name}" for name in normalized_inputs)

    return "hub", "default fallback host for shared or unclear changes", evidence


def build_commands(host: str) -> dict[str, list[str]]:
    return {
        "quick": [
            f"nix develop -c nix eval .#nixosConfigurations.{host}.config.system.build.toplevel.outPath",
            "nix develop -c nix flake check --no-build",
        ],
        "full": [
            f"nix develop -c nix build .#nixosConfigurations.{host}.config.system.build.toplevel",
            "nix develop -c nix flake check",
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Pick the cheapest relevant validation host for flake or module updates."
    )
    parser.add_argument("--path", action="append", default=[], help="Changed repo path")
    parser.add_argument("--input", action="append", default=[], help="Changed flake input")
    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="Output format",
    )
    args = parser.parse_args()

    host, reason, evidence = infer_host(args.path, args.input)
    payload = {
        "host": host,
        "reason": reason,
        "evidence": evidence,
        "commands": build_commands(host),
    }

    if args.format == "json":
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 0

    print(f"host: {payload['host']}")
    print(f"reason: {payload['reason']}")
    if payload["evidence"]:
        print("evidence:")
        for item in payload["evidence"]:
            print(f"  - {item}")
    print("quick:")
    for command in payload["commands"]["quick"]:
        print(f"  - {command}")
    print("full:")
    for command in payload["commands"]["full"]:
        print(f"  - {command}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
