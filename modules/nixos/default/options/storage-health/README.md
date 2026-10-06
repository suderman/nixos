# Storage failure handling

## Why this exists

On October 3, 2026, Kit's replaceable game NVMe disappeared at PCIe address
`0000:70:00.0`. Btrfs aborted its transaction and forced the filesystem read-only.
Hourly btrbk jobs continued attempting game snapshots. MOTD generation also
queried optional volumes every five minutes. Warm reboot and PCI rescan did not
recover the controller; removing power did.

The retained journal reveals another problem. At October 3 19:17:55, kernel
allocation profiling attributed about 57.5 GiB to
`nvidia/nv-vm.c:538`, `nv_alloc_system_pages`. At October 2 20:01:40, before the
storage failure, the same site accounted for about 57.7 GiB. NVIDIA DRM started
reporting NVKMS allocation failures and fallback to system memory on October 2
at 18:12:26. These direct page allocations explain why ordinary RSS, page cache,
and slab did not account for the memory pressure. They do not identify which
GPU workload or driver behavior retained those pages, or prove a leak.

The bad boot ran Linux 6.18.53 and NVIDIA 595.71.05. The recovered host runs
6.18.54 with the same NVIDIA version. Do not attribute the whole workstation
collapse to the SSD, Btrfs, Docker, or Sunshine without further evidence.

## Filesystem policy

Kit, Lux, Pow, and Eve opt into the same module. `services.storage-health.volumes`
declares each filesystem's primary mount, all mount aliases, expected logical
backing devices, and any dependent services. Devices default to the existing
`fileSystems` declaration. Controller names and UUIDs come from sysfs and cached
udev metadata, so NVMe enumeration changes do not change the policy.

- Kit monitors boot/main plus data and game. Data includes `/home/jon/data` and
  Ollama. Main and boot are monitored but never automatically unmounted.
- Lux monitors boot/main plus data and pool. Data failure stops its Immich
  server container and Backblaze container. Pool failure stops Backblaze, Samba's
  file server, and NFS exports. Docker itself and unrelated containers remain up.
  Media-library paths inside Plex, Jellyfin, and Arr are not declared in this
  flake, so their consumers still need live inspection before adding stop rules.
- Pow and Eve monitor both expected members of their pool. Their single data
  profile is intentional: capacity locally, backup copies at separate sites.
  A missing expected member is treated as a hard failure. This is not a general
  policy for a mirrored Btrfs filesystem that can safely remain operational.
- Lux's RAID enclosure owns member health. The guard watches its one logical
  device for disappearance or filesystem failure, not individual RAID members.

No RAID profile, snapshot retention, or valuable-volume backup target changes.
Kit game remains excluded from btrbk because its content is replaceable. Existing
snapshots are not deleted.

## Detection and containment

`storage-health.timer` checks every 15 seconds after its previous check finishes.
It reads proc/sysfs, cached udev metadata and a bounded kernel-journal window.
The detector never stats filesystem paths, runs Btrfs ioctls, or sends disk commands.

Loss of an expected device, an offline controller, forced read-only state, or a
matching hard kernel error latches a failure. For secondary filesystems, the guard
runtime-masks and asynchronously stops every declared mount and automount alias.
It also stops only that volume's space sampler, scheduled btrbk jobs and declared
consumers. Marker files under `/run/storage-health/blocked/` inhibit further jobs.
Mount masking applies to fstab-generated units; do not replace these with static
units in a higher-priority systemd load path without revisiting this policy.

Increasing Btrfs counters or other matching I/O errors suspend jobs and alert,
but do not automatically unmount a still-operational filesystem. The first
observed counters establish a baseline; historical errors alone do not quarantine
storage on every reboot. Boot/main errors alert and suspend their background
jobs without trying to unmount root. Unknown-device errors capture and alert
without guessing which filesystem to stop.

The latch survives healthy metadata returning. Acknowledgement is manual within
this boot. A reboot clears `/run`; an absent device is detected again. Secondary
mounts retain `nofail`, their existing device wait, and on-demand behavior. New
mount attempts have a per-volume `mountTimeoutSec` limit (15 seconds by default)
and device-bound stop propagation. Lux pool uses 120 seconds because a read-only
mount took 31 seconds during diagnosis.

`startupGraceSec` defaults to zero. Lux pool uses 60 seconds after boot for its
USB enclosure to appear. During this window, a never-seen, wholly absent and
unmounted volume reports `waiting for devices` without latching a failure.
Once any expected device has been observed, loss fails immediately. Mounted
filesystems, offline controllers, kernel errors and expired grace periods still
use normal detection. Manual rearm always rejects missing devices, even during
boot grace. Grace does not clear an existing failure latch.

## MOTD without filesystem probes

MOTD lists every declared volume, including unmounted and quarantined ones.
`storage-space-NAME.service` samples each already-mounted, healthy volume every
five minutes. It uses `O_PATH` to avoid triggering an idle automount, verifies
the descriptor mount ID still matches mountinfo, then calls `fstatvfs` through
that descriptor. This handles the idle-unmount race without sampling the empty
underlying directory.
Nested mount aliases must have permanently accessible parent directories.

Each sampler is one non-overlapping unit with a 10-second start limit, 64 MiB
memory ceiling and no swap. It never holds the detector lock. If it sticks in
kernel I/O, that volume loses fresh samples rather than blocking the detector or
other volumes. No sampling runs while its failure latch is set.

The guard publishes the original-style filesystem table to
`/run/storage-health-motd/status.txt`: device, mount, type, used/total capacity,
and green/yellow/red usage bars. Device and type come from cached mount metadata.
Unmounted, quarantined, read-only and unsampled volumes remain visible. Warnings
label last-known capacity and samples older than ten minutes.

Rust MOTD reads only that cache. Login reads its usual pre-generated MOTD.
The footer shows an absolute sample timestamp, not an age that would freeze
between MOTD refreshes. The displayed state can be up to one MOTD refresh behind;
`storage-health status` reads the newer status cache without sudo. Caches are
cleared at reboot, so an idle disk can initially say `space not sampled` until
normal use mounts it. No periodic mount just for display.

## Independent backup jobs

Snapshot timers are per source, such as `btrbk-snapshots-data.timer`. Send timers
are per source and destination, such as `btrbk-backups-main-0.timer` and
`btrbk-backups-main-1.timer`. Destination numbers follow the declared target list.
The old aggregate configs remain available for manual use, but have no timers;
manual aggregate commands do not gain the per-volume unit guards.

Jobs check the failure marker before mounting their source. Mount and directory
setup run in `ExecStartPre`, not during NixOS activation. `RequiresMountsFor` is
not used for these jobs because systemd queues dependencies before evaluating
conditions. A failed data volume therefore cannot block main's job or activation.

Snapshots have a 10-minute limit; sends have six hours. Each job has a 15-second
stop limit, 1 GiB memory ceiling, 128 MiB swap ceiling and 128-task ceiling. The
shared `btrbk.slice` caps concurrent jobs at 2 GiB memory, 128 MiB swap and 256
tasks, with lower CPU/I/O weights. Large initial backups may need deliberate
limit increases. Jobs can run concurrently; a failed destination does not delay
the other destination's unit. Existing minimum snapshot retention remains six
hours. Check backup success after deployment rather than assuming a timer ran.

SSH connections as `btrbk` are noninteractive, have a 10-second connect timeout
and 15-second keepalives with two missed replies allowed. SSH keepalives detect
an unresponsive peer, not a hung remote filesystem while sshd still answers.
The job timeout bounds the latter in userspace; remote kernel D-state work may
outlive the connection. Incoming btrbk sessions are not randomly killed. Pool
mount quarantine blocks new access but cannot revoke their existing descriptors.

Swap, earlyoom, systemd-oomd, Sunshine, and unrelated services remain unchanged.

## Severe pressure

The same timer watches PSI `full avg10`, available memory and D-state threads.
It enters an alarm after either:

- I/O full pressure at least 60% for 120 seconds.
- I/O full pressure at least 30%, with available memory below 5% or at least
  20 D-state threads, for 60 seconds.
- Memory full pressure at least 20%, with available memory below 5%, for
  60 seconds.

Recovery requires five minutes with I/O full below 10%, memory full below 5%,
and available memory at least 5%. A sampling gap over 45 seconds resets dwell.
These conservative thresholds can still alert on legitimate sustained heavy
work. They capture and alert; they never kill workloads to hide pressure.

## Diagnostics and alerts

A separate bounded oneshot captures root-only bundles under
`/run/storage-health/incident-*`, retaining three. It saves full meminfo,
allocation profiling, VM counters, PSI, swap, slab/buddy/zone information,
cgroup memory statistics, mountinfo, thread wait channels, recent kernel logs,
Btrfs sysfs error counters, controller metadata, and PSS for the 20 largest RSS
processes. `nvidia-smi` runs last with a timeout. Proc/sysfs evidence is saved
first, before driver probes. Each large input/output is capped; allocinfo has
its own 16 MiB cap. The collector has a 192 MiB memory ceiling, no swap, 32-task
ceiling and a 75-second start limit. The detector is capped at 128 MiB. Its former
64 MiB ceiling caused a cgroup OOM during live build activity; 128 MiB leaves
headroom for journal/process scans.

Entry, new containment/pressure escalation, and recovery create alerts. Remote
alerts use the existing `https://ntfy.hub/storage` topic; subscribe to it in the
existing ntfy client. Kit also sends a local critical desktop notification to
Jon's user DBus. Headless hosts need no desktop user. Failed remote delivery
retries at most every five minutes without repeating the desktop message.
Pending updates replace older unsent messages.
The journal always receives the alert text and diagnostic path.

Bundles are tmpfs, not durable backups. Copy them to healthy storage before
reboot or cold power-off. Do not persist them to the game drive:

```sh
sudo storage-health status
sudo cp -a /run/storage-health/incident-* /path/on/healthy/storage/
```

A service stuck in uninterruptible kernel I/O cannot be rescued by its timeout.
Systemd prevents overlapping checks/collectors; limits prevent an accumulating
userspace job queue. Mount masking cannot revoke existing file descriptors or
stop kernel workers. Steam may still hold the failed filesystem; close Steam
when possible. This design reduces new activity and captures evidence. It
cannot guarantee desktop responsiveness during a driver leak or kernel hang.
There is no automatic reboot, PCI reset, repair, scrub, force-unmount, writable
remount, or random process kill.

## Recovery

Inspect controller and kernel state, save diagnostics, and fix the hardware or
perform a deliberate cold power cycle if needed. Do not repeatedly remount a
read-only Btrfs filesystem writable. If recovery happens within the same boot:

```sh
sudo storage-health rearm data
```

Use the declared volume name, such as `data`, `pool`, or `game`. Rearm rejects
missing expected devices, offline controllers and mounted read-only filesystems.
It acknowledges old Btrfs counters, removes that volume's mount masks and marker,
and starts only its automount units. It does not mount the filesystem, reset
counters, or restart applications. Timed jobs resume at their next schedule.
Restart stopped application services explicitly after checking storage. Consumers
that depend on several volumes remain inhibited until all markers are cleared.
Further errors latch a new failure.

## Controller prevention and hardware follow-up

Live topology is main SN850X `02:00.0` below CPU port `00:06.0`, T500 `03:00.0`
below PCH port `00:1a.0`, and game SN850X `70:00.0` below PCH port `00:1d.0`.
The game path is distinct, but not the only chipset path. Its root port does
not advertise ASPM support. All three endpoint links currently show ASPM
disabled. Endpoint runtime power control is `on`; the game root port is `auto`
but active with no recorded runtime suspend time. `d3cold_allowed` is 1.
APST is enabled and permits the game drive's deep idle states. The D3cold error
is evidence of an inaccessible PCIe/controller path, not proof that APST caused
it. The kernel's simple-suspend quirk comes from ACPI platform policy.

Both WD drives report firmware `620331WD`; T500 reports `P8CR002`. Board BIOS
is `17.03`, dated May 2, 2025. Verify current approved BIOS and exact-model WD
firmware with the vendors. Do not flash firmware selected from a forum report.
No specific SN850X fix for 6.18.54 was established in this investigation.

The board manual says M2_1 uses the CPU and its heatsink. M2_2/M2_3 use the
chipset and supplied thermal pads intended to make full contact with a chassis
metal plate. Check pad thickness, removed liners, actual contact, airflow, and
GPU/riser clearance. Physical contact cannot be verified from software. Both
SN850X drives have historical warning-temperature time; cooling deserves work
even though temperature alone does not explain this failure.

If recurrence warrants a controlled APST trial, the kernel supports a narrower
per-controller PM QoS limit of zero through
`/sys/class/nvme/<controller>/power/pm_qos_latency_tolerance_us`. Match the game
serial first and verify APST readback after a successful change. It is a
runtime setting, not persistent policy, and can raise idle power/temperature.
Stabilize cooling first. No APST, ASPM, port-PM or D3cold change is enabled here.
Do not start by disabling PCIe power management globally.

Sources:

- [Linux open(2), O_PATH and untriggered automounts](https://man7.org/linux/man-pages/man2/open.2.html).
- [ASRock manual, storage specification and M.2 thermal-pad instructions](https://download.asrock.com/Manual/Z790%20PG-ITXTB4.pdf), printed pages 4 and 40-44.
- [Linux 6.18 NVMe core, per-controller latency and APST](https://github.com/torvalds/linux/blob/v6.18/drivers/nvme/host/core.c).
- [Linux 6.18 NVMe PCI driver, ACPI simple suspend](https://github.com/torvalds/linux/blob/v6.18/drivers/nvme/host/pci.c).

Run the synthetic checks without hardware failure:

```sh
nix develop -c nix build .#checks.x86_64-linux.storage-health -L
```
