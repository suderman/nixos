from __future__ import annotations

import hashlib
import os
import sys
from pathlib import Path


def profile_names(profiles_dir: Path) -> list[str]:
    if not profiles_dir.is_dir():
        return []

    names: list[str] = []
    for entry in sorted(profiles_dir.iterdir(), key=lambda p: p.name):
        if entry.name.startswith(".") or not entry.is_dir():
            continue
        if not (entry / "config.yaml").exists():
            continue
        names.append(entry.name)
    return names


def assign_ports(base: int, names: list[str], salt: str) -> dict[str, int]:
    max_offset = 65535 - base - 1
    if max_offset <= 0:
        raise SystemExit(f"base port {base} leaves no room for profile ports")

    window = min(4096, max_offset)
    used = {base}
    assigned: dict[str, int] = {}

    for name in names:
        digest = hashlib.sha256(f"{base}:{salt}:{name}".encode()).digest()
        preferred = int.from_bytes(digest[:4], "big") % window
        for step in range(window):
            port = base + 1 + ((preferred + step) % window)
            if port not in used:
                used.add(port)
                assigned[name] = port
                break
        else:
            raise SystemExit(f"unable to allocate port for profile {name}")

    return assigned


def rewrite_env_base(root_env_base: Path, profile_env_base: Path, api_port: int, dashboard_port: int) -> None:
    lines = root_env_base.read_text().splitlines() if root_env_base.exists() else []
    replacements = {
        "API_SERVER_ENABLED": "1",
        "API_SERVER_PORT": str(api_port),
        "DASHBOARD_PORT": str(dashboard_port),
    }

    rewritten: list[str] = []
    seen = set()

    for line in lines:
        key, sep, value = line.partition("=")
        if sep and key in replacements:
            rewritten.append(f"{key}={replacements[key]}")
            seen.add(key)
        else:
            rewritten.append(line)

    for key, value in replacements.items():
        if key not in seen:
            rewritten.append(f"{key}={value}")

    profile_env_base.write_text("\n".join(rewritten) + "\n")
    profile_env_base.chmod(0o600)


def main() -> int:
    profiles_dir = Path(sys.argv[1])
    root_env_base = Path(sys.argv[2])
    api_base = int(sys.argv[3])
    dashboard_base = int(sys.argv[4])

    names = profile_names(profiles_dir)
    api_ports = assign_ports(api_base, names, "api")
    dashboard_ports = assign_ports(dashboard_base, names, "dashboard")

    for name in names:
        profile_home = profiles_dir / name
        rewrite_env_base(
            root_env_base,
            profile_home / ".env.base",
            api_ports[name],
            dashboard_ports[name],
        )
        print(f"{name}\t{api_ports[name]}\t{dashboard_ports[name]}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
