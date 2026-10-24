# DaVinci Resolve Home Manager module

This directory defines `programs.davinci-resolve`. It installs Resolve and repairs
AAC audio that Resolve on Linux cannot decode.

## Files

- `default.nix` defines the options, the `davinci-resolve-aac` and
  `davinci-resolve-export` commands, and the user service.
- `davinci-resolve-aac.py` is the standard-library Media Pool watcher and
  remuxer.

Kit's settings live in `hosts/kit/users/jon/home-configuration.nix`.

## Options

| Option                | Default                             | Purpose                                                          |
| --------------------- | ----------------------------------- | ---------------------------------------------------------------- |
| `enable`              | `false`                             | Install Resolve and the helpers                                  |
| `package`             | `pkgs.davinci-resolve`              | Resolve package; kit uses `pkgs.unstable.davinci-resolve-studio` |
| `aacRepair.enable`    | `false`                             | Run the Media Pool watcher                                       |
| `aacRepair.directory` | `~/.local/share/DaVinciResolve/AAC` | Where repaired copies go; kit uses `~/data/media/AAC`            |

`~/.local/share/DaVinciResolve` is persisted to storage, including the project
library and the `license` directory that the Studio wrapper binds into the
package, so activation survives reboots. Its `Extras` subdirectory holds AI
models from the Extras Download Manager, tens of gigabytes that Resolve can
download again, so it persists to scratch without snapshots or backups. Keep the activation key in a password
manager. Resolve only accepts it through its activation dialog.

## AAC repair

The watcher needs Resolve Studio's external scripting. Resolve Free does not
accept external scripts. Set this once in Resolve:

Preferences > System > General > External scripting using: **Local**

Then import footage as usual. Every four seconds the `davinci-resolve-aac`
user service checks the current bin, newest clips first, and scans the whole
Media Pool every 30 seconds. For each clip it:

1. Reads only the `File Path` property. Calling `GetClipProperty()` with no
   key leaks native memory in Resolve's Linux scripting bridge.
2. Runs `ffprobe` on the file and skips anything without AAC audio, offline
   media, timelines, and files already in the repair directory.
3. Remuxes into the repair directory. FFmpeg copies the video, timecode, other
   audio, and subtitle streams, decodes each AAC stream to 24-bit PCM, and
   writes MOV. If MOV rejects a stream, FFmpeg retries with video and audio
   only and converts all audio to PCM.
4. Validates the result: same video codecs, same number of audio streams, no
   AAC, and a duration within 0.5 s or 1 %. The source must not have changed
   during the run.
5. Moves the finished file into place without overwriting anything, then calls
   `ReplaceClipPreserveSubClip()`, falling back to `ReplaceClip()`.

The service converts one file at a time and holds a lock in the repair
directory, so a manual `repair` cannot convert the same file concurrently.
After each conversion it rescans the current bin before taking the next file
from the backlog. It reconnects when Resolve starts, exits, or switches
projects. It restarts itself above 256 MiB of memory.

The service never writes to the original files and does not edit timelines.
Timeline clips that use a relinked Media Pool item follow it.

### Commands

```sh
davinci-resolve-aac status          # Resolve connection, repaired files, failures
davinci-resolve-aac repair FILE...  # remux without Resolve; prints the new paths
journalctl --user -u davinci-resolve-aac -f
systemctl --user restart davinci-resolve-aac
```

The commands run Python inside the Resolve package's FHS wrapper, because
`fusionscript.so` needs libraries that only exist there. The scripting module
and `fusionscript.so` come from the same package's `passthru.davinci`. FFmpeg
runs without the wrapper's `LD_LIBRARY_PATH`. Both the watcher and Resolve
see only paths visible inside the wrapper, which excludes most of `/etc`.

### Failures

Errors appear in the journal at error priority (`journalctl --user -p err`).
When FFmpeg cannot repair a file, the watcher writes
`<name>.<digest>.mov.failed` with the FFmpeg output, sends one desktop
notification, and leaves the clip linked to the original. It does not retry
that file, even after a restart. To retry, delete the `.failed` file and
restart the service. Probe
errors, such as a file still being copied, and clips Resolve refuses to relink
are retried with backoff up to 5 minutes, then reported once.

### Storage

Repaired files are named `<original name>.<digest>.mov`. The digest covers the
source path, size, and modification time, so a changed or moved source gets a
new file and never reuses an old one. Existing repaired files are never
overwritten or deleted.

Resolve projects link to these files. Deleting one leaves the clip offline,
and nothing cleans the directory automatically. Expect each file to be the
size of the original plus about 17 MB per minute of 48 kHz stereo audio.

Keep the directory on persistent, backed-up storage. On kit it sits beside
Resolve's `CacheClip` on the data disk, which btrbk backs up to pow. Back up
or move the directory together with the projects that use it. Before removing
old repairs, check which projects still link to them.

## Export

`davinci-resolve-export FILE...` writes `<name>-final.mp4` with AAC audio for
upload, since Resolve on Linux cannot encode AAC. It copies H.264 and HEVC
video without re-encoding, and re-encodes anything else with x264 at CRF 20.
It refuses to overwrite an existing output. For the fastest export, render
H.264 or H.265 with Linear PCM audio in Resolve Studio.

## Limitations

- The watcher only relinks Media Pool items. Timeline clips follow their item.
- FFmpeg's AAC decoder keeps the encoder's end padding, so repaired audio can
  run up to about 21 ms past the video. The start stays aligned.
- The fallback drops streams that MOV rejects, such as SubRip subtitles or some
  camera telemetry. The journal names the error when this happens.
- Variable frame rate, unusual edit lists, and damaged files have not been
  tested against Resolve.
- Resolve 21 marks keyed `GetClipProperty(name)` as deprecated in favor of the
  unkeyed form that leaks. Check the scripting README after each Resolve
  update. It is at `Developer/Scripting/README.md` inside
  `passthru.davinci`.
