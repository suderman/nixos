"""Archive Linux filenames that the Windows backup client cannot open."""

import hashlib
import os
import re
import sys
import tarfile
import tempfile
from pathlib import Path


RESERVED = re.compile(r"^(CON|PRN|AUX|NUL|COM[1-9¹²³]|LPT[1-9¹²³])(?:\.|$)", re.I)


def incompatible(name):
    return (
        name.endswith((" ", "."))
        or bool(RESERVED.match(name))
        or any(
            ord(c) < 32 or 0xD800 <= ord(c) <= 0xDFFF or c in '<>:"/\\|?*' for c in name
        )
    )


def candidates(root, excluded):
    pending = [(root, False)]
    while pending:
        parent, inherited = pending.pop()
        with os.scandir(parent) as entries:
            for entry in entries:
                path = Path(entry.path)
                if path in excluded:
                    continue
                bad = inherited or incompatible(entry.name)
                if entry.is_dir(follow_symlinks=False):
                    pending.append((path, bad))
                    if bad:
                        yield path
                elif bad and (
                    entry.is_file(follow_symlinks=False) or entry.is_symlink()
                ):
                    yield path


def digest(path):
    try:
        with open(path, "rb") as stream:
            return hashlib.file_digest(stream, "sha256").digest()
    except OSError as error:
        raise RuntimeError("Unable to read archive for comparison") from error


def archive(root, destination, excluded, label):
    paths = sorted(candidates(root, excluded))
    staging = destination / ".pending"
    staging.mkdir(mode=0o700, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{label}-", dir=staging)
    os.close(fd)
    target = destination / f"{label}.tar"
    try:
        with tarfile.open(temporary, "w", format=tarfile.PAX_FORMAT) as output:
            for path in paths:
                before = path.lstat()
                output.add(
                    path, arcname=f"{label}/{path.relative_to(root)}", recursive=False
                )
                after = path.lstat()
                if (before.st_size, before.st_mtime_ns, before.st_ino) != (
                    after.st_size,
                    after.st_mtime_ns,
                    after.st_ino,
                ):
                    raise RuntimeError("A source changed while being archived")
        changed = not target.exists() or digest(temporary) != digest(target)
        if changed:
            os.replace(temporary, target)
        print(
            f"{label}: {len(paths)} members, {target.stat().st_size} bytes, updated={changed}"
        )
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    destination = Path(sys.argv[1])
    destination.mkdir(mode=0o700, parents=True, exist_ok=True)
    for label, location in zip(
        ("drive_d", "drive_e", "drive_f", "drive_g"), sys.argv[2:], strict=True
    ):
        root = Path(location)
        excluded = {destination, root / ".bzvol"}
        if label == "drive_e":
            excluded.update(
                root / name
                for name in (
                    "backblaze",
                    "docker/overlay",
                    "docker/overlay2",
                    "docker/image",
                    "docker/buildkit",
                )
            )
        archive(root, destination, excluded, label)


if __name__ == "__main__":
    main()
