"""Copy legacy state into native homes after stopping Pi. Sources stay intact."""

import argparse
import filecmp
import os
import shutil
import tempfile
from pathlib import Path


def legacy_link(source, target):
    return (
        source.is_file()
        and not source.is_symlink()
        and target.is_symlink()
        and target.resolve() == source.resolve()
    )


def plan(home, skip_fff=False):
    mappings = [
        (".local/state/pi/sessions", ".pi/agent/sessions"),
        (".local/state/pi/pi-lens", ".pi-lens"),
        (".config/pi/pi-lens.json", ".pi-lens/config.json"),
    ]
    if not skip_fff:
        mappings.append((".local/state/pi/fff", ".pi/agent/fff"))
    entries = {}
    for old, new in mappings:
        source, target = home / old, home / new
        if not os.path.lexists(source):
            continue
        paths = [source]
        if source.is_dir() and not source.is_symlink():
            paths += sorted(source.rglob("*"))
        for path in paths:
            destination = target / path.relative_to(source)
            for parent in destination.parents:
                if parent == home:
                    break
                if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
                    raise ValueError(f"Unsafe destination parent: {parent}")
            if not (path.is_symlink() or path.is_dir() or path.is_file()):
                raise ValueError(f"Unsupported source: {path}")
            prior = entries.get(destination, destination)
            if os.path.lexists(prior):
                same = (
                    legacy_link(path, prior)
                    or (
                        path.is_symlink()
                        and prior.is_symlink()
                        and path.readlink() == prior.readlink()
                    )
                    or (
                        not path.is_symlink()
                        and not prior.is_symlink()
                        and (
                            (path.is_dir() and prior.is_dir())
                            or (
                                path.is_file()
                                and prior.is_file()
                                and filecmp.cmp(path, prior, shallow=False)
                            )
                        )
                    )
                )
                if not same:
                    raise ValueError(f"Conflicting destination: {destination}")
            entries[destination] = path
    return entries


def migrate(home, apply=False, skip_fff=False):
    entries = plan(home, skip_fff)
    missing = [
        (source, target)
        for target, source in entries.items()
        if not os.path.lexists(target) or legacy_link(source, target)
    ]
    if apply:
        for source, target in missing:
            target.parent.mkdir(parents=True, exist_ok=True)
            if legacy_link(source, target):
                with tempfile.TemporaryDirectory(dir=target.parent) as directory:
                    temporary = Path(directory) / "state"
                    shutil.copy2(source, temporary)
                    if not legacy_link(source, target):
                        raise ValueError(f"Destination changed: {target}")
                    # Replace only the link to this exact source, not a user's file.
                    os.replace(temporary, target)
            elif source.is_symlink():
                target.symlink_to(source.readlink())
            elif source.is_dir():
                target.mkdir(mode=source.stat().st_mode & 0o777)
            else:
                # Exclusive creation also protects against a new destination after preflight.
                with source.open("rb") as reader, target.open("xb") as writer:
                    shutil.copyfileobj(reader, writer)
                shutil.copystat(source, target)
        plan(home, skip_fff)
    return len(missing)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply", action="store_true", help="copy after stopping all Pi processes"
    )
    parser.add_argument(
        "--skip-fff",
        action="store_true",
        help="keep existing native FFF databases; retain legacy databases",
    )
    args = parser.parse_args()
    try:
        count = migrate(Path.home(), args.apply, args.skip_fff)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Migration refused: {error}\n")
    print(
        f"{'Copied' if args.apply else 'Would copy'} {count} entries; legacy sources retained."
    )
