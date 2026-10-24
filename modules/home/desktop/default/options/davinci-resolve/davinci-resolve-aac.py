"""Repair AAC audio in DaVinci Resolve's Media Pool.

Resolve on Linux cannot decode AAC, so clips import with silent audio. This
helper finds Media Pool items whose files contain AAC, remuxes them into a
separate directory with the video copied and the AAC decoded to PCM, and
relinks the item with ReplaceClipPreserveSubClip(). Originals are only read.

Design follows broskisworld/davinci-aac-support (MIT) and the Media Pool
watcher in RayDurlok/DaVinci-Resolve-AAC-Scripts-for-Linux (GPL, ideas only):
keyed GetClipProperty() calls only, since the unkeyed form leaks native memory,
newest clips in the current bin first, a bounded full scan, and retry backoff.

Commands:
  watch          poll Resolve and repair new Media Pool items (systemd service)
  repair FILE..  remux files without Resolve and print the repaired paths
  status         show the Resolve connection and the repaired-media directory
"""

import argparse
import fcntl
import hashlib
import json
import os
import subprocess
import sys
import time

FULL_SCAN_SECONDS = 30
MAX_BACKOFF_SECONDS = 300
MAX_ATTEMPTS = 6
MAX_RSS_MIB = 256

# The FHS wrapper's LD_LIBRARY_PATH serves fusionscript.so, but would load the
# sandbox's glibc into Nix-built ffmpeg and notify-send.
TOOL_ENV = {k: v for k, v in os.environ.items() if k != "LD_LIBRARY_PATH"}


def log(message, error=False):
    # journald reads the <N> prefix as the syslog priority
    print(("<3>" if error else "") + message, flush=True)


class ConversionError(Exception):
    """A conversion problem worth retrying later."""


class ConversionFailed(ConversionError):
    """FFmpeg could not repair this file; a .failed marker records why."""

    def __init__(self, message, new):
        super().__init__(message)
        self.new = new  # False when the marker predates this attempt


class Repairer:
    def __init__(self, args):
        self.ffmpeg = args.ffmpeg
        self.ffprobe = args.ffprobe
        self.notify = args.notify
        self.output_dir = os.path.realpath(args.output_dir)
        self.probes = {}

    def run_probe(self, path):
        result = subprocess.run(
            [
                self.ffprobe,
                "-v",
                "error",
                "-print_format",
                "json",
                "-show_streams",
                "-show_format",
                path,
            ],
            capture_output=True,
            text=True,
            timeout=120,
            env=TOOL_ENV,
        )
        if result.returncode != 0:
            raise ConversionError(
                f"ffprobe failed on {path}: {result.stderr.strip()[-500:]}"
            )
        return json.loads(result.stdout)

    def signature(self, path):
        st = os.stat(path)
        return f"{os.path.realpath(path)}\0{st.st_size}\0{st.st_mtime_ns}"

    def probe(self, path):
        """Cached ffprobe result for this exact file version."""
        key = self.signature(path)
        if key not in self.probes:
            self.probes[key] = self.run_probe(path)
        return self.probes[key]

    def has_aac(self, path):
        return any(s.get("codec_name") == "aac" for s in self.probe(path)["streams"])

    def is_repaired(self, path):
        return os.path.dirname(os.path.realpath(path)) == self.output_dir

    def output_path(self, path):
        # The digest covers path, size, and mtime, so a changed or different
        # source never reuses another file's conversion.
        digest = hashlib.sha256(self.signature(path).encode()).hexdigest()[:16]
        stem = os.path.splitext(os.path.basename(path))[0][:120]
        return os.path.join(self.output_dir, f"{stem}.{digest}.mov")

    def plans(self, probe):
        """FFmpeg output arguments, most faithful first."""
        streams = [
            s
            for s in probe["streams"]
            if not s.get("disposition", {}).get("attached_pic")
        ]

        def build(selected, audio_codec):
            args = []
            for out, s in enumerate(selected):
                args += ["-map", f"0:{s['index']}"]
                if s.get("codec_type") == "audio":
                    args += [f"-c:{out}", audio_codec(s)]
                else:
                    args += [f"-c:{out}", "copy"]
            return args

        # Every stream (timecode, data, other audio) with only AAC decoded
        full = build(
            streams, lambda s: "pcm_s24le" if s.get("codec_name") == "aac" else "copy"
        )
        # Video and audio only, when MOV rejects some other stream
        av = [s for s in streams if s.get("codec_type") in ("video", "audio")]
        safe = build(av, lambda s: "pcm_s24le")
        return [full] if full == safe else [full, safe]

    def validate(self, source, output):
        src = [
            s
            for s in source["streams"]
            if not s.get("disposition", {}).get("attached_pic")
        ]
        out = self.run_probe(output)
        dst = out["streams"]

        def kinds(streams, kind):
            return [s.get("codec_name") for s in streams if s.get("codec_type") == kind]

        if "aac" in kinds(dst, "audio"):
            raise ConversionError("output still contains AAC")
        if kinds(dst, "video") != kinds(src, "video"):
            raise ConversionError(
                f"video streams differ: {kinds(src, 'video')} -> {kinds(dst, 'video')}"
            )
        if len(kinds(dst, "audio")) != len(kinds(src, "audio")):
            raise ConversionError("audio stream count differs")
        try:
            a = float(source["format"]["duration"])
            b = float(out["format"]["duration"])
        except (KeyError, ValueError):
            return
        if abs(a - b) > max(0.5, a * 0.01):
            raise ConversionError(f"duration differs: {a:.2f}s -> {b:.2f}s")

    def convert(self, path):
        """Return the repaired copy of path, converting it if needed.

        Returns None while another process holds the conversion lock.
        """
        final = self.output_path(path)
        if os.path.exists(final):
            return final
        failed = final + ".failed"
        if os.path.exists(failed):
            raise ConversionFailed(
                f"earlier conversion failed; delete {failed} to retry", new=False
            )

        os.makedirs(self.output_dir, exist_ok=True)
        with open(os.path.join(self.output_dir, ".lock"), "w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return None
            if os.path.exists(final):
                return final
            return self.convert_locked(path, final, failed)

    def convert_locked(self, path, final, failed):
        before = self.signature(path)
        source = self.probe(path)
        partial = final + ".partial"
        errors = []
        started = time.monotonic()
        log(f"converting {path}")
        for attempt, plan in enumerate(self.plans(source)):
            command = [
                self.ffmpeg,
                "-nostdin",
                "-hide_banner",
                "-loglevel",
                "error",
                "-y",
                "-i",
                path,
                *plan,
                "-map_metadata",
                "0",
                "-movflags",
                "+use_metadata_tags",
                "-f",
                "mov",
                partial,
            ]
            result = subprocess.run(
                command, capture_output=True, text=True, env=TOOL_ENV
            )
            try:
                if result.returncode != 0:
                    raise ConversionError(
                        f"ffmpeg exited {result.returncode}: {result.stderr.strip()[-800:]}"
                    )
                self.validate(source, partial)
                if attempt:
                    log(f"kept only video and audio for {path}: {errors[0][:300]}")
                break
            except ConversionError as e:
                errors.append(str(e))
                if os.path.exists(partial):
                    os.remove(partial)
        else:
            with open(failed, "w") as f:
                f.write(f"{path}\n\n" + "\n\n".join(errors) + "\n")
            raise ConversionFailed(f"conversion failed: {errors[-1]}", new=True)

        if self.signature(path) != before:
            os.remove(partial)
            raise ConversionError("source changed during conversion; will retry")

        with open(partial, "rb") as f:
            os.fsync(f.fileno())
        try:
            os.link(partial, final)  # never replaces an existing file
            os.remove(partial)
        except PermissionError:
            os.rename(partial, final)  # no hard links; the lock still guards final
        dir_fd = os.open(self.output_dir, os.O_RDONLY)
        try:
            os.fsync(dir_fd)
        finally:
            os.close(dir_fd)
        log(f"converted in {time.monotonic() - started:.0f}s: {final}")
        return final

    def alert(self, title, body):
        if self.notify:
            subprocess.run(
                [self.notify, "-a", "DaVinci Resolve", title, body],
                check=False,
                env=TOOL_ENV,
            )


def connect(args):
    os.environ["RESOLVE_SCRIPT_API"] = args.script_api
    os.environ["RESOLVE_SCRIPT_LIB"] = args.script_lib
    modules = os.path.join(args.script_api, "Modules")
    if modules not in sys.path:
        sys.path.append(modules)
    import DaVinciResolveScript

    resolve = DaVinciResolveScript.scriptapp("Resolve")
    if resolve is None or resolve.GetProjectManager() is None:
        return None
    return resolve


def rss_mib():
    with open("/proc/self/statm") as f:
        return int(f.read().split()[1]) * os.sysconf("SC_PAGE_SIZE") / 2**20


class Watcher:
    def __init__(self, args):
        self.args = args
        self.repairer = Repairer(args)
        self.reset()

    def reset(self):
        self.done = set()  # media ids that need nothing more this project
        self.retry = {}  # media id -> (attempts, monotonic time)
        self.next_full_scan = 0.0

    def items(self, pool):
        """Current bin newest first, then the whole pool every 30 seconds."""
        current = pool.GetCurrentFolder() or pool.GetRootFolder()
        items = list(reversed(current.GetClipList() or []))
        if time.monotonic() >= self.next_full_scan:
            folders = [pool.GetRootFolder()]
            while folders:
                folder = folders.pop()
                items += folder.GetClipList() or []
                folders += folder.GetSubFolderList() or []
            self.next_full_scan = time.monotonic() + FULL_SCAN_SECONDS
        return items

    def defer(self, media_id, name, reason):
        attempts = self.retry.get(media_id, (0, 0))[0] + 1
        if attempts >= MAX_ATTEMPTS:
            log(f"giving up on {name}: {reason}", error=True)
            self.repairer.alert("AAC repair failed", f"{name}\n{reason}")
            self.done.add(media_id)
            self.retry.pop(media_id, None)
            return
        delay = min(5 * 2**attempts, MAX_BACKOFF_SECONDS)
        self.retry[media_id] = (attempts, time.monotonic() + delay)
        log(f"{name}: {reason}; retrying in {delay}s", error=True)

    def process(self, item, may_convert):
        """Handle one Media Pool item. Returns True if it ran a conversion."""
        media_id = item.GetMediaId()
        if not media_id or media_id in self.done:
            return False
        if self.retry.get(media_id, (0, 0))[1] > time.monotonic():
            return False

        path = item.GetClipProperty("File Path")
        if not path or self.repairer.is_repaired(path):
            self.done.add(media_id)  # timelines, generators, or already relinked
            return False
        name = os.path.basename(path)
        if not os.path.isfile(path):
            # Offline media may come back; check again later without logging.
            self.retry[media_id] = (0, time.monotonic() + FULL_SCAN_SECONDS)
            return False

        try:
            if not self.repairer.has_aac(path):
                self.done.add(media_id)
                return False
            converted = os.path.exists(self.repairer.output_path(path))
            if not converted and not may_convert:
                return False
            if not converted:
                log(f"AAC audio in {path}")
            repaired = self.repairer.convert(path)
        except ConversionFailed as e:
            log(f"{name}: {e}", error=True)
            if e.new:
                self.repairer.alert("AAC repair failed", f"{name}\n{e}")
            self.done.add(media_id)
            return e.new
        except ConversionError as e:
            self.defer(media_id, name, str(e))
            return not converted
        except (OSError, subprocess.SubprocessError, ValueError) as e:
            self.defer(media_id, name, str(e))
            return False
        if repaired is None:
            return False  # another process holds the lock

        if item.ReplaceClipPreserveSubClip(repaired) or item.ReplaceClip(repaired):
            log(f"relinked {name} -> {repaired}")
            self.done.add(media_id)
            self.retry.pop(media_id, None)
        else:
            self.defer(media_id, name, f"Resolve rejected {repaired}")
        return not converted

    def run(self):
        resolve = None
        project_id = None
        interval = self.args.interval
        log(f"watching for Resolve; repaired media goes to {self.repairer.output_dir}")
        while True:
            if resolve is None:
                try:
                    resolve = connect(self.args)
                except ImportError as e:
                    log(f"cannot load Resolve scripting: {e}", error=True)
                    return 1
                if resolve is None:
                    time.sleep(interval)
                    continue
                log(
                    f"connected to {resolve.GetProductName()} {resolve.GetVersionString()}"
                )
            converted = False
            try:
                manager = resolve.GetProjectManager()
                if manager is None:
                    raise ConnectionError("Resolve exited")
                project = manager.GetCurrentProject()
                if project is not None:
                    if project.GetUniqueId() != project_id:
                        project_id = project.GetUniqueId()
                        self.reset()
                        log(f"project: {project.GetName()}")
                    for item in self.items(project.GetMediaPool()):
                        if self.process(item, may_convert=not converted):
                            converted = True
            except Exception as e:  # the scripting bridge raises arbitrary errors
                log(f"lost Resolve connection: {e}")
                resolve = None
                project_id = None
            if rss_mib() > MAX_RSS_MIB:
                log(f"memory above {MAX_RSS_MIB} MiB; restarting")
                return 0
            # After a conversion, rescan at once so fresh imports go next.
            if not converted:
                time.sleep(interval)


def repair_files(args):
    repairer = Repairer(args)
    status = 0
    for path in (os.path.join(args.cwd, f) for f in args.files):
        try:
            if repairer.is_repaired(path) or not repairer.has_aac(path):
                print(f"skip (no AAC): {path}", file=sys.stderr)
                continue
            repaired = repairer.convert(path)
            if repaired is None:
                raise ConversionError("another conversion is running; try again")
            print(repaired)
        except (ConversionError, OSError) as e:
            print(f"error: {path}: {e}", file=sys.stderr)
            status = 1
    return status


def show_status(args):
    try:
        resolve = connect(args)
    except Exception as e:
        resolve = None
        print(f"Resolve scripting: cannot load fusionscript ({e})")
    if resolve is None:
        print(
            "Resolve: not reachable. Is it running with Preferences > System > "
            "General > External scripting using set to Local?"
        )
    else:
        manager = resolve.GetProjectManager()
        project = manager.GetCurrentProject() if manager else None
        print(
            f"Resolve: {resolve.GetProductName()} {resolve.GetVersionString()}, "
            f"project {project.GetName() if project else 'none'}"
        )

    out = args.output_dir
    names = os.listdir(out) if os.path.isdir(out) else []
    movs = [n for n in names if n.endswith(".mov")]
    size = sum(os.path.getsize(os.path.join(out, n)) for n in movs)
    print(f"Repaired media: {out}: {len(movs)} files, {size / 2**30:.1f} GiB")
    for name in sorted(n for n in names if n.endswith(".failed")):
        with open(os.path.join(out, name)) as f:
            print(f"failed: {f.readline().strip()} ({name})")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--ffmpeg", default="ffmpeg")
    parser.add_argument("--ffprobe", default="ffprobe")
    parser.add_argument("--notify")
    parser.add_argument("--script-api", default="/opt/resolve/Developer/Scripting")
    parser.add_argument(
        "--script-lib", default="/opt/resolve/libs/Fusion/fusionscript.so"
    )
    parser.add_argument("--interval", type=float, default=4)
    parser.add_argument("--cwd", default=".", help="base for relative FILE arguments")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("watch")
    commands.add_parser("status")
    commands.add_parser("repair").add_argument("files", nargs="+")
    args = parser.parse_args()

    if args.command == "watch":
        return Watcher(args).run()
    if args.command == "repair":
        return repair_files(args)
    return show_status(args)


if __name__ == "__main__":
    sys.exit(main())
