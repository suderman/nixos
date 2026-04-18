from __future__ import annotations

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


def derive_port(base: int, name: str, salt: str) -> int:
    """
    Derive a stable profile port from only the base port and profile name.

    This deliberately does not depend on the set of other profiles, so adding or
    removing a sibling profile cannot renumber existing profile ports.
    """
    max_offset = 65535 - base - 1
    if max_offset <= 0:
        raise SystemExit(f"base port {base} leaves no room for profile ports")

    value = 5381
    for char in f"{salt}:{name}":
        value = ((value * 33) + ord(char)) % max_offset

    return base + 1 + value


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
    for name in names:
        profile_home = profiles_dir / name
        api_port = derive_port(api_base, name, "api")
        dashboard_port = derive_port(dashboard_base, name, "dashboard")
        rewrite_env_base(
            root_env_base,
            profile_home / ".env.base",
            api_port,
            dashboard_port,
        )
        print(f"{name}\t{api_port}\t{dashboard_port}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
