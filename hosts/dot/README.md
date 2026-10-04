# dot on Linode

`dot` is a host-only-trust NixOS server, not a migration of sol. This runbook
covers a new installation and repair separately. Do not run installation commands
against an existing filesystem. Provisioning, disk writes, deployment and public
services require Jon's explicit deployment mandate.

## Design and commissioning record

The prepared configuration uses x86_64-linux, the locked stable kernel, BIOS GRUB
on GPT, a 1 MiB BIOS boot partition, 1 GiB ext4 `/boot`, 2 GiB swap and Btrfs.
`root` is erased at each boot. `/nix` and the top-level `/mnt/main` are persistent.
`storage`, `scratch` and `snapshots` are subvolumes below `/mnt/main`.

Only SSH, Tailscale, logging, local snapshots and health checks are enabled.
There is no Home Manager, NetworkManager, Blocky, Traefik, Docker, keyd or app.
DHCP runs on `eth0`; IPv6 SLAAC is enabled with privacy addresses disabled.
Resolvers are `1.1.1.1` and `9.9.9.9`. IPv6 is provisional until provider tests.
Do not publish an AAAA record before it works. No home subnet routes are accepted.
Automatic upgrades, reboots and garbage collection are off during commissioning.
`stateVersion = "26.05"` is a new-host compatibility choice, not a fleet change.

Toronto and a 2 GiB shared-CPU plan are provisional. Public catalog checks on
2026-10-04 confirmed [Toronto `ca-central`](https://api.linode.com/v4/regions/ca-central)
and [`g6-standard-1`, Linode 2GB](https://api.linode.com/v4/linode/types/g6-standard-1):
2048 MB RAM, one vCPU, 51200 MB disk and 2000 GB transfer. The API reports a base
monthly price of 12.00 and hourly price of 0.018, with no Toronto regional
price override. Confirm billing currency, taxes, capacity and the final quote
before approval. VM idle usage does not establish workload suitability.

No instance was provisioned or inspected during this task. No instance/disk/profile
IDs, IPs, image checksums or provider console results have been verified. Record
actual values here after provisioning is authorized. Unassigned values below are
inputs, not operational records.

| Profile     | Provider profile ID        | `/dev/sda`                     | `/dev/sdb`                  | Root device   | Kernel          |
| ----------- | -------------------------- | ------------------------------ | --------------------------- | ------------- | --------------- |
| `installer` | unassigned                 | raw system disk, ID unassigned | raw ISO disk, ID unassigned | `/dev/sdb`    | Direct Disk     |
| `nixos`     | unassigned                 | same raw system disk           | unassigned                  | `/dev/sda`    | Direct Disk     |
| rescue      | record on each rescue boot | explicitly selected disk       | explicitly selected disk    | rescue system | provider rescue |

Keep the installer disk until console, rollback, restore and second-boot checks
pass. Linode Backups does not support this partitioned Btrfs system disk.
Provider disk expansion, guest partition expansion and Btrfs expansion are
separate operations. Do not resize as part of bootstrap.

### Trust boundary

The host deliberately does not import `flake.nixosModules.default`. It reuses
shared persistence and tmpfiles, Linode hardware, Disko, agenix and agenix-rekey.
It receives only its own private host key and host-specific console password
hash. Jon's login keys are public authorization, not private user identities.
It receives no fleet root hex, CA signing key, user private key or shared btrbk
key. There are **no initial encrypted service secrets** to rekey.

`fleet-root-independent` keeps dot out of `nixos generate` and the fleet root
rotation target scanner. Keep it. Neither command rotates dot's independent
host key. The initial host key was derived on a trusted operator with salt `dot`
and BIP-85 hex32 index 1. Its committed fingerprint is:

```text
SHA256:2ufHWpYkMZ76p2VFxZ05L/3XprZABp7lMmqliZHA0tY
```

Keep the original seed and index metadata offline, including after later fleet
root rotation. Possession of dot's private key cannot derive the root. A trusted
operator can recover dot's key from the original root. If this trust policy needs
broader fleet identity changes, review those separately before deployment.

## New installation

### 1. Prepare the trusted operator

Run on a trusted Nix machine with enough disk space to build the closures.
Use a reviewed repository revision containing this host. Do not update inputs.
You need Linode Cloud Manager/API rights for creation, profiles, firewall, rescue
and LISH. Verify LISH access before closing any network path. Use a source IP you
control for temporary SSH ingress and a distinct temporary SSH login key.

Command template, operator:

```sh
: "${REPO_REV:?Set the reviewed full repository commit containing dot}"
: "${REPO:?Set a fresh operator checkout path}"
git clone https://github.com/suderman/nixos.git "$REPO"
cd "$REPO"
git checkout --detach "$REPO_REV"
test "$(git rev-parse HEAD)" = "$REPO_REV"
test -z "$(git status --porcelain)"
nix develop
```

Continue in that devshell, using Bash:

```sh
set -euo pipefail
umask 077
WORK=$(mktemp -d "${TMPDIR:-/tmp}/dot-bootstrap.XXXXXXXX")
chmod 700 "$WORK"
STAGING="$WORK/staging"
mkdir -m700 "$STAGING"
ssh-keygen -q -t ed25519 -N '' -C dot-temporary-installer -f "$WORK/installer-login"
BOOTSTRAP_KEY="$WORK/installer-login"
KNOWN_HOSTS="$WORK/known_hosts"
: >"$KNOWN_HOSTS"
NIXPKGS_NODE=$(jq -er '.nodes.root.inputs.nixpkgs | select(type == "string")' flake.lock)
jq -r --arg node "$NIXPKGS_NODE" '.nodes[$node].locked.rev' flake.lock
jq -r '.nodes.disko.locked.rev' flake.lock
ANYWHERE=$(nix build .#nixosConfigurations.dot.pkgs.nixos-anywhere --no-link --print-out-paths)/bin/nixos-anywhere
OPENSSL=$(nix build .#nixosConfigurations.dot.pkgs.openssl --no-link --print-out-paths)/bin/openssl
"$ANYWHERE" --help
```

At preparation time root nixpkgs is `nixpkgs_12`, revision
`774debe7a0d1b496e35677ad955a1011c6ff74f3`; Disko is
`725ea35e410ad83be4931d1bff7e090eacaf3563`; nixos-anywhere is 1.13.0.
Recheck for your selected revision. These are locked tools, not unpinned
`github:` installer invocations. Avoid the broad `nixos add host` and
`nixos generate` wrappers.

Keep `WORK` private and outside the repository. Do not put staging into a flake,
git, a derivation, terminal history or an unencrypted transfer service. Cleanup
commands are in step 12. Keep this shell open through installation.

Expected result: reviewed checkout, pinned installer, private temporary login
key, empty known-hosts file. No remote change yet.

### 2. Create the provider resources and record mappings

**Provider action template, only after deployment is authorized.** Create an
empty instance labelled `dot`, x86_64, one public interface, no VPC, no image
installation and no application services. Confirm region, plan, price and disk
budget. Attach a Cloud Firewall before boot. Allow SSH only from the operator's
verified source IP, required DHCP traffic for the chosen interface model, IPv6
router advertisements/neighbor discovery and essential ICMP. Allow outbound DNS,
HTTPS, Nix downloads and Tailscale connectivity. Do not open TCP 12345.

Create two raw disks. Size the ISO disk from step 3's actual bytes plus at least
64 MiB margin, rounding up to provider MiB units. The system disk needs the
partition sizes above plus space for Nix closures, snapshots and free-space
headroom. Create the profiles exactly as the table specifies. Disable provider
filesystem resize/check, distro/network configuration and boot helpers that
assume ext4 without a partition table. Disable shutdown watchdog/Lassie during
installation. Leave it disabled for commissioning; enabling it later requires
an observed clean shutdown and recovery test.

Record actual instance ID, public IPv4/IPv6, interface type, firewall ID, disk
IDs, disk sizes and both profile IDs. Check Cloud Manager's selected instance
label and every mapping. Do not infer mappings from disk order.

Operator command template after recording values:

```sh
: "${LINODE_ID:?Set the verified new Linode ID}"
: "${SYSTEM_DISK_ID:?Set its verified raw system disk ID}"
: "${INSTALLER_DISK_ID:?Set its verified raw installer disk ID}"
: "${INSTALLER_PROFILE_ID:?Set the verified installer profile ID}"
: "${FINAL_PROFILE_ID:?Set the verified nixos profile ID}"
: "${PUBLIC_IP:?Set its verified public IPv4}"
[[ "$LINODE_ID" =~ ^[0-9]+$ ]]
[[ "$SYSTEM_DISK_ID" =~ ^[0-9]+$ && "$INSTALLER_DISK_ID" =~ ^[0-9]+$ ]]
[[ "$INSTALLER_PROFILE_ID" =~ ^[0-9]+$ && "$FINAL_PROFILE_ID" =~ ^[0-9]+$ ]]
test "$SYSTEM_DISK_ID" != "$INSTALLER_DISK_ID"
test "$INSTALLER_PROFILE_ID" != "$FINAL_PROFILE_ID"
printf 'dot Linode=%s system=%s installer=%s final-profile=%s\n' \
  "$LINODE_ID" "$SYSTEM_DISK_ID" "$INSTALLER_DISK_ID" "$FINAL_PROFILE_ID"
```

Direct Disk boots the selected root disk's MBR. This layout needs guest BIOS GRUB
and the EF02 BIOS boot partition. Do not select provider GRUB 2 or import
upstream `virtualisation/linode-config.nix`/`linode-image.nix`, which use a
different partitionless ext4/swap layout and `device = "nodev"`.

Expected result: confirmed resource record and console access, not an installed
system.

### 3. Verify the standard installer ISO and write only its disk

Operator command template. Select a standard NixOS minimal x86_64 installer from
an official release page. Record exact release URL, ISO URL, byte size and
SHA-256. Verify the checksum through the release source, independently of the
file download. Do not substitute this flake's custom ISO: it has weak passwords,
a moving-main downloader and an unencrypted host-key receiver.

```sh
: "${ISO_URL:?Set the selected official ISO URL}"
: "${ISO_SHA256:?Set its independently verified release SHA-256}"
[[ "$ISO_SHA256" =~ ^[0-9a-fA-F]{64}$ ]]
curl --fail --location --proto '=https' "$ISO_URL" -o "$WORK/installer.iso"
printf '%s  %s\n' "$ISO_SHA256" "$WORK/installer.iso" | sha256sum --check
ISO_BYTES=$(stat -c %s "$WORK/installer.iso")
INSTALLER_MIB=$(( (ISO_BYTES + 64*1024*1024 + 1024*1024 - 1) / (1024*1024) ))
printf 'ISO bytes=%s; minimum installer disk MiB=%s\n' "$ISO_BYTES" "$INSTALLER_MIB"
```

Provider: boot rescue, explicitly map the two disks, and record which guest
block device is the installer disk. Rescue mappings are independent of normal
profiles. Verify disk sizes with `lsblk -b -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS`.
Use LISH to set temporary rescue SSH authorization if supported and read its
SSH host public key/fingerprint. Otherwise use the provider's rescue console
transfer method. Never trust `ssh-keyscan` without a console fingerprint match.

Operator: write the console-verified rescue host key into `KNOWN_HOSTS` under
`PUBLIC_IP`. Configure a host-key-checked rescue SSH session using the temporary
login key; copy the verified ISO:

```sh
ssh -i "$BOOTSTRAP_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile="$KNOWN_HOSTS" "root@$PUBLIC_IP" true
scp -i "$BOOTSTRAP_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile="$KNOWN_HOSTS" "$WORK/installer.iso" "root@$PUBLIC_IP:/root/installer.iso"
```

**Destructive command template, rescue console.** Re-enter verified values
there. The following writes the ISO disk, never the raw system disk:

```sh
set -euo pipefail
: "${LINODE_ID:?Set and verify the console belongs to the dot Linode ID}"
: "${INSTALLER_DISK_ID:?Set and verify the rescue-mapped installer disk ID}"
: "${INSTALLER_DEVICE:?Set its verified rescue block device, not a guess}"
: "${SYSTEM_DEVICE:?Set the separately verified rescue system block device}"
: "${ISO_SHA256:?Set the recorded release SHA-256}"
test -b "$INSTALLER_DEVICE" && test -b "$SYSTEM_DEVICE"
test "$(readlink -f "$INSTALLER_DEVICE")" != "$(readlink -f "$SYSTEM_DEVICE")"
printf '%s  /root/installer.iso\n' "$ISO_SHA256" | sha256sum --check
lsblk -b -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$INSTALLER_DEVICE" "$SYSTEM_DEVICE"
test "$(lsblk -bdno SIZE "$INSTALLER_DEVICE")" -ge \
  "$(( $(stat -c %s /root/installer.iso) + 64*1024*1024 ))"
printf 'Writing ONLY installer disk %s (%s) on Linode %s\n' \
  "$INSTALLER_DISK_ID" "$INSTALLER_DEVICE" "$LINODE_ID"
read -r -p 'Type WRITE-INSTALLER to confirm this mapping: ' confirmation
test "$confirmation" = WRITE-INSTALLER
dd if=/root/installer.iso of="$INSTALLER_DEVICE" bs=4M conv=fsync status=progress
sync
```

Expected result: verified ISO on the positively identified installer disk. The
system disk is untouched. Provider: shut down rescue and explicitly boot the
`installer` profile with `/dev/sdb` as root and Direct Disk.

### 4. Secure the running installer

NixOS installer console, as root through LISH (`sudo -i` if necessary):

```sh
set -euo pipefail
grep -qx 'VARIANT_ID=installer' /etc/os-release
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
ip -br address
ip route
ip -6 route
lspci -nnk
```

Confirm raw system disk is `/dev/sda`, ISO disk `/dev/sdb`, network is `eth0` and
the detected storage drivers match `hardware-configuration.nix`. If not, correct
the host hardware module and rebuild before formatting. Hardware detection must
not add duplicate filesystem declarations. Confirm DHCP, IPv4 connectivity,
IPv6 SLAAC, DNS and firewall attachment. Verify console belongs to `LINODE_ID`.

Paste **only** the operator's temporary `installer-login.pub` into the console.
Do not paste the final private host key. Command template, installer console:

```sh
: "${BOOTSTRAP_PUBKEY:?Paste the temporary operator public login key}"
install -d -m700 /root/.ssh
printf '%s\n' "$BOOTSTRAP_PUBKEY" >/root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
install -d /run/systemd/system/sshd.service.d
cat >/run/systemd/system/sshd.service.d/bootstrap.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/run/current-system/sw/bin/sshd -D -f /etc/ssh/sshd_config -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o PermitRootLogin=prohibit-password
EOF
sshd -t -f /etc/ssh/sshd_config -o PasswordAuthentication=no \
  -o KbdInteractiveAuthentication=no -o PermitRootLogin=prohibit-password
systemctl daemon-reload
systemctl restart sshd
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
cat /etc/ssh/ssh_host_ed25519_key.pub
```

Operator: replace the rescue known-host entry with this console-verified
installer public key. Do not disable host checking. Set up these shell variables
and arrays in the operator shell, using actual key text:

```sh
: "${INSTALLER_HOST_PUBKEY:?Set the public SSH host key read through installer console}"
ssh-keygen -R "$PUBLIC_IP" -f "$KNOWN_HOSTS"
printf '%s %s\n' "$PUBLIC_IP" "$INSTALLER_HOST_PUBKEY" >>"$KNOWN_HOSTS"
SSH=(ssh -F /dev/null -i "$BOOTSTRAP_KEY" -o IdentitiesOnly=yes -o BatchMode=yes \
  -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$KNOWN_HOSTS")
"${SSH[@]}" "root@$PUBLIC_IP" 'grep -qx VARIANT_ID=installer /etc/os-release; id -u'
```

Expected result: root-capable, host-key-checked installer SSH, with password and
keyboard-interactive authentication disabled and public ingress source-restricted.

### 5. Prepare final identity and recovery files before building

Operator: recover the **original index-1** root on a trusted machine. Do not
change the repository master seed or run `agenix import` over existing master
files merely to recover dot. The command below assumes the original canonical
root is still `/run/agenix/hex` on that trusted machine. If it has rotated, use
an offline private file containing the original root and adapt only the input
redirection. Verify the public key before using it. Do not print the root.

```sh
test ! -e secrets/rotation/ACTIVE
HOST_KEY="$STAGING/mnt/main/storage/etc/ssh/ssh_host_ed25519_key"
RECOVERY_HASH="$STAGING/mnt/main/storage/etc/dot/recovery.hash"
MACHINE_ID="$STAGING/mnt/main/storage/etc/machine-id"
install -d -m700 "$(dirname "$HOST_KEY")" "$(dirname "$RECOVERY_HASH")"
sudo -n bash -c '"$1" hex dot </run/agenix/hex' bash "$(command -v derive)" \
  | derive ssh >"$HOST_KEY"
chmod 600 "$HOST_KEY"
ssh-keygen -y -f "$HOST_KEY" >"$WORK/final-host.pub"
test "$(cut -d ' ' -f 1,2 "$WORK/final-host.pub")" = \
  "$(cut -d ' ' -f 1,2 hosts/dot/ssh_host_ed25519_key.pub)"
ssh-keygen -lf "$WORK/final-host.pub"
```

Generate a long host-specific recovery password in a password manager, save it
offline and enter it at OpenSSL's password prompt. The same host-local hash is
used for root console login and Jon's sudo/password recovery. It is never used
for public SSH password authentication. Do not use a fleet password here.

```sh
"$OPENSSL" passwd -6 >"$RECOVERY_HASH"
chmod 600 "$RECOVERY_HASH"
grep -Eq '^\$6\$[^:[:space:]]+$' "$RECOVERY_HASH"
"$OPENSSL" rand -hex 16 >"$MACHINE_ID"
chmod 444 "$MACHINE_ID"
grep -Eq '^[0-9a-f]{32}$' "$MACHINE_ID"
test "$(cat "$MACHINE_ID")" != 00000000000000000000000000000000
```

Keep the machine-id with the recovery record or restore it from backup. A new
replacement may use a new ID if no old state is restored, but it must not be
zero. Do not put password hashes in git/store. Final paths have three views:

| View           | Host private key                                        |
| -------------- | ------------------------------------------------------- |
| operator       | `STAGING/mnt/main/storage/etc/ssh/ssh_host_ed25519_key` |
| installer      | `/mnt/mnt/main/storage/etc/ssh/ssh_host_ed25519_key`    |
| installed host | `/mnt/main/storage/etc/ssh/ssh_host_ed25519_key`        |

The hash is beside `storage/etc/dot/recovery.hash`, machine-id at
`storage/etc/machine-id`. `/var/lib/nixos`, `/home/jon` and `/var/lib/tailscale`
persist in `storage`; `/var/log` and coredumps persist in `scratch`. `/boot` and
`/nix/var/nix/profiles/system*` retain boot entries and generations. Local storage
snapshots do **not** include scratch logs or future Docker state.

Check secrets and recipient before building:

```sh
nix eval --json .#nixosConfigurations.dot.config.age.secrets
nix eval --json .#nixosConfigurations.dot.config.age.identityPaths
nix eval --raw .#nixosConfigurations.dot.config.age.rekey.hostPubkey
```

Expected result: `{}` secrets, exact persistent host-key identity path and the
committed dot public recipient. No missing-key fallback. For a future specific
service credential, declare only that secret's `rekeyFile`, encrypt its source
with the existing master workflow and run `agenix rekey -a` on the trusted
operator before building. This command considers all configured nodes and
stages changed ciphertext. Inspect its complete git diff and include required
ciphertext in the reviewed source. It has no host selector at this pin. Never
run it on dot or deploy the master identity there. No such secret is needed
for this initial installation; Tailscale enrolment is interactive in step 9.

### 6. Evaluate and build locally

Operator:

```sh
nix eval --raw .#nixosConfigurations.dot.config.system.build.toplevel.outPath
SYSTEM=$(nix build .#nixosConfigurations.dot.config.system.build.toplevel \
  --out-link "$WORK/system" --print-out-paths)
DISKO=$(nix build .#nixosConfigurations.dot.config.system.build.diskoScript \
  --out-link "$WORK/disko" --print-out-paths)
MOUNT=$(nix build .#nixosConfigurations.dot.config.system.build.mountScript \
  --out-link "$WORK/mount" --print-out-paths)
nix eval --json .#nixosConfigurations.dot.config.fileSystems
nix eval --json .#nixosConfigurations.dot.config.boot.loader.grub.devices
nix eval --json .#nixosConfigurations.dot.config.networking.firewall.allowedTCPPorts
nix eval --json .#nixosConfigurations.dot.config.networking.firewall.allowedUDPPorts
nix eval --json .#nixosConfigurations.dot.config.services.openssh.settings
```

Expected GRUB devices: exactly `["/dev/sda"]`, no `nodev` and no forced install.
Review build logs, enabled services, serial console and staged file permissions.
All needed source files must be committed or deliberately added to git before
flake evaluation; untracked files are not included. Never add `STAGING`.

### 7. Install through an authenticated local tunnel, without reboot

nixos-anywhere 1.13.0 hardcodes `UserKnownHostsFile=/dev/null` and
`StrictHostKeyChecking=no` before appended options. Appending stricter duplicate
`--ssh-option` values does not fix it. Instead the outer ordinary SSH connection
below authenticates the installer. Inner traffic only reaches the installer
through its loopback port. Keep the listener on the trusted operator, bound to
`127.0.0.1`; do not share that endpoint with untrusted local users.

Operator command template:

```sh
: "${TUNNEL_PORT:?Choose an unused local TCP port between 1024 and 65535}"
[[ "$TUNNEL_PORT" =~ ^[0-9]+$ ]]
test "$TUNNEL_PORT" -ge 1024 && test "$TUNNEL_PORT" -le 65535
# A busy port fails the tunnel's ExitOnForwardFailure check.
"${SSH[@]}" -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=15 \
  -L "127.0.0.1:$TUNNEL_PORT:127.0.0.1:22" "root@$PUBLIC_IP" &
TUNNEL_PID=$!
sleep 2
kill -0 "$TUNNEL_PID"
"${SSH[@]}" "root@$PUBLIC_IP" 'lsblk -b -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS'
: "${LINODE_ID:?Set the verified new Linode ID}"
: "${SYSTEM_DISK_ID:?Set the verified disk mapped to installer /dev/sda}"
printf 'FORMAT dot Linode=%s system disk=%s guest=/dev/sda\n' "$LINODE_ID" "$SYSTEM_DISK_ID"
read -r -p 'Type FORMAT-DOT after checking console and mappings: ' confirmation
test "$confirmation" = FORMAT-DOT
# DESTRUCTIVE: repartitions and formats /dev/sda on that verified new instance.
"$ANYWHERE" --flake .#dot --build-on local --phases disko,install \
  --ssh-option ControlPath=none --no-substitute-on-destination \
  --extra-files "$STAGING" -i "$BOOTSTRAP_KEY" -p "$TUNNEL_PORT" root@127.0.0.1
```

There is no kexec or reboot phase. An already-running NixOS installer is detected
through `VARIANT_ID=installer`; installation does not depend on Linode kexec.
Omitting kexec selects root SSH in 1.13.0. Do not use `--copy-host-keys`, which
would copy the temporary installer identity to the wrong path. The VM test below
exercises this authenticated-tunnel and extra-files route separately from the
upstream `--vm-test` flag, which rejects `--extra-files` in 1.13.0.

Expected result: Disko filesystems mounted below `/mnt`, final system installed,
private identity/hash/ID staged in persistent storage, GRUB installed, installer
still running. Installation output alone does not prove final boot works.

### 8. Inspect, stop, select the final profile

Operator, through authenticated outer SSH:

```sh
"${SSH[@]}" "root@$PUBLIC_IP" 'set -e
  findmnt -R /mnt
  lsblk -f
  test -s /mnt/boot/grub/grub.cfg
  grep -F "console=ttyS0,19200n8" /mnt/boot/grub/grub.cfg
  ssh-keygen -lf /mnt/mnt/main/storage/etc/ssh/ssh_host_ed25519_key
  stat -c "%a %U %n" /mnt/mnt/main/storage/etc/ssh/ssh_host_ed25519_key \
    /mnt/mnt/main/storage/etc/dot/recovery.hash
  test -s /mnt/mnt/main/storage/etc/machine-id
  readlink -f /mnt/nix/var/nix/profiles/system
  sync'
```

Match final key fingerprint with step 5; private key and hash must be root-owned
mode 600. Keep the password in the password manager. Stop here on any GRUB error,
wrong mapping or identity mismatch. Do not set `forceInstall` to suppress it.

Installer console: `sync; umount -R /mnt; swapoff -a; poweroff`.
Operator: `kill "$TUNNEL_PID"; wait "$TUNNEL_PID" || true`.
Provider: select the recorded **nixos** profile, `/dev/sda` root, `/dev/sdb`
unassigned, Direct Disk, helpers off. Explicitly boot that profile. Do not issue
an ordinary installer reboot which can select the installer profile again.

Expected result: boot from guest BIOS GRUB on system disk, not ISO.

### 9. Verify first boot and enrol Tailscale before closing public SSH

Provider LISH: interact with GRUB at 19200 baud, boot the selected generation,
then log in as root with the host-specific recovery password. Verify `id -u`
returns `0`. A login prompt alone is insufficient. Keep provider rescue access
independent of both network and root mount. Check `systemctl --failed`.

Operator: replace installer host entry with the known final public key:

```sh
ssh-keygen -R "$PUBLIC_IP" -f "$KNOWN_HOSTS"
printf '%s %s\n' "$PUBLIC_IP" "$(cat "$WORK/final-host.pub")" >>"$KNOWN_HOSTS"
# Use Jon's existing authorized private login key, NOT the temporary installer key.
: "${JON_LOGIN_KEY:?Set the existing Jon private login key path on the operator}"
FINAL_SSH=(ssh -F /dev/null -i "$JON_LOGIN_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile="$KNOWN_HOSTS")
"${FINAL_SSH[@]}" "jon@$PUBLIC_IP" 'hostname; cat /etc/machine-id; ip -br address'
```

Installed host, Jon SSH or root console:

```sh
sudo systemctl is-active sshd tailscaled
sudo systemctl show dot-identity -p Result -p ExecMainStatus --no-pager
for mount in / /boot /nix /mnt/main; do findmnt "$mount"; done
getent hosts cache.nixos.org
curl -4 --fail --head https://cache.nixos.org
curl -6 --fail --head https://cache.nixos.org
sudo tailscale up --hostname=dot --accept-routes=false --accept-dns=false
sudo tailscale status
sudo tailscale ip -4
```

Use the interactive enrolment URL on the trusted operator; do not save an auth
key in git or history. Test IPv6 routing and RA, not only assigned addresses.
If dual stack fails, record the observed failure and make an explicit temporary
host-local IPv6 disable; rebuild and retest. Do not change other hosts.

Record actual Tailscale IP only after enrolment. Update `zones/tail/default.nix`
on the operator using its existing shape, with dot's real address, and rebuild
this host. `networking.domain = "tail"` is deliberate. Until then, use explicit
bootstrap/public IPs, not an invented `dot.tail` address or sol's old IP.

Operator: add final public key to known-hosts under the actual tail IP, set
`TAIL_IP`, open a **new** SSH session to `jon@$TAIL_IP` and test sudo. Before
removing source-limited public SSH ingress, verify this new session and a fresh
password-authenticated LISH console login. Keep UDP 41641 reachable as required
by Tailscale; this is not Tailscale SSH, so tailnet access alone does not replace
OpenSSH key checks.

Installed host: record machine-id, key fingerprint, Nix generation, password
login, journal, Tailscale status and persistent-path inventory. Place a temporary
marker in `/home/jon`, `/var/lib/nixos` and `/var/lib/tailscale`, and one disposable
file on `/`. Reboot through the final profile. Verify persistent markers,
unchanged key/ID, journal from previous boot and renewed tailnet SSH; root-only
file must disappear. Remove all markers. Do not mark commissioning done until
backup/restore and cold rollback below also pass.

### 10. Set up independent backups and prove a restore

Local hourly btrbk snapshots include `storage`, with a minimum 6 hours and
24-hour/3-day retention. Journal is bounded to 128 MiB and 7 days in `scratch`.
The health timer fails at 85% usage on `/boot` or `/mnt/main`, or if a verified
off-host backup acknowledgement is missing/older than 48 hours. Failure is
visible in systemd/journal; it deliberately fails before backups are configured.
Arrange an external monitor to poll `dot-health`/SSH availability and alert Jon.
An isolated local failed unit is not an off-host alert.

Select an independent backup host and encrypted destination filesystem, with
space, retention and monitoring. Generate a **dedicated** ed25519 backup key
there. Its private key stays on the backup host, never on dot. Copy only its
public key to `hosts/dot/backup-host.pub`, commit it and add to dot's configuration:

```nix
dot.backupPublicKey = builtins.readFile ./backup-host.pub;
```

Rebuild dot from the operator. Null default means no backup account/key is active
before this decision. Enabled access creates `dot-backup` with a forced command
implemented by `backup-send.sh`: list storage snapshots, send an existing
read-only storage snapshot, acknowledge successful backup. No remote shell,
forwarding, snapshot deletion, other subvolume reads or destination writes.
The source host holds no credential to write/delete backups anywhere. Keep
snapshot directories root-owned; do not allow apps to create symlinks there.

Command template, backup host, using dot's verified host key and tail IP:

```sh
set -euo pipefail
: "${TAIL_IP:?Set the verified dot tail IP}"
: "${BACKUP_LOGIN_KEY:?Set the dedicated private backup key on the backup host}"
: "${BACKUP_KNOWN_HOSTS:?Set a file containing the verified dot SSH host key}"
: "${BACKUP_DIR:?Set an encrypted, mounted Btrfs backup directory}"
findmnt -T "$BACKUP_DIR"
BSSH=(ssh -F /dev/null -i "$BACKUP_LOGIN_KEY" -o IdentitiesOnly=yes -o BatchMode=yes \
  -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$BACKUP_KNOWN_HOSTS" "dot-backup@$TAIL_IP")
SNAPSHOT=$("${BSSH[@]}" list | tail -1)
[[ "$SNAPSHOT" =~ ^storage\.[0-9]{8}T[0-9]{4}$ ]]
# Full sends avoid dependence on a base snapshot at either end.
"${BSSH[@]}" "send $SNAPSHOT" | sudo btrfs receive "$BACKUP_DIR"
sudo btrfs property get -ts "$BACKUP_DIR/$SNAPSHOT" ro
sudo test -s "$BACKUP_DIR/$SNAPSHOT/etc/machine-id"
"${BSSH[@]}" acknowledge
```

Schedule this from the backup host and alert on command failure, backup age,
source/destination space and missing snapshots. Do not resend the same snapshot
into an existing receive path. Destination retention/deletion is backup-host
policy, not dot's authority. Set short initial retention and inspect actual space
use on this small disk. Root/boot/Nix closures are reproducible from the selected
revision; password hash, host key, machine-id and tail state need protected backup.

Sample restore, backup host, without overwriting live dot:

```sh
: "${RESTORE_DIR:?Set a new, empty directory on a mounted Btrfs test filesystem}"
test -d "$RESTORE_DIR" && test -z "$(ls -A "$RESTORE_DIR")"
sudo btrfs send "$BACKUP_DIR/$SNAPSHOT" | sudo btrfs receive "$RESTORE_DIR"
sudo cmp "$BACKUP_DIR/$SNAPSHOT/etc/machine-id" "$RESTORE_DIR/$SNAPSHOT/etc/machine-id"
sudo ssh-keygen -lf "$RESTORE_DIR/$SNAPSHOT/etc/ssh/ssh_host_ed25519_key"
sudo test -s "$RESTORE_DIR/$SNAPSHOT/etc/dot/recovery.hash"
# Delete ONLY this disposable restored subvolume after recording the result.
sudo btrfs subvolume delete "$RESTORE_DIR/$SNAPSHOT"
```

The restored key must match dot, and recovered password must allow console login
in a disposable restore VM or authorized replacement. Never boot two copies of
one machine-id/Tailscale identity concurrently. Before adding apps, inventory
persistent paths, use explicit storage bind mounts and application-consistent
DB dumps. `/var/lib/docker` in scratch is not covered. Add resource limits and
bounded restarts before enabling heavy workloads.

### 11. Normal updates, rollback and repair

Operator: use the reviewed checkout, locked tools and host-key-checked transport.
Build locally and copy the closure, then switch on the installed host:

```sh
: "${TAIL_IP:?Set the verified dot tail IP}"
SYSTEM=$(nix build .#nixosConfigurations.dot.config.system.build.toplevel \
  --out-link "$WORK/system-update" --print-out-paths)
export NIX_SSHOPTS="-F /dev/null -i $JON_LOGIN_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$KNOWN_HOSTS"
nix copy --to "ssh://root@$TAIL_IP" "$SYSTEM"
"${FINAL_SSH[@]}" "root@$TAIL_IP" \
  "nixos-rebuild switch --no-reexec --store-path '$SYSTEM'"
```

Use simple paths without whitespace for `NIX_SSHOPTS`. This update uses root
public-key SSH, not password SSH or an unattended sudo password prompt. Jon also
has passwordless `nixos-rebuild`, matching fleet remote rebuild practice. Inspect failed units,
new sessions, memory, free space and generation after switching. Run a normal
remote rebuild test once commissioning has console recovery available.

Installed host rollback:

```sh
sudo nixos-rebuild switch --rollback --no-reexec
readlink -f /run/current-system
sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
```

`--no-reexec` uses the installed pinned rebuild command. Without it, even a
rollback tries to rebuild that command from a local NixOS configuration, which
this remote-build-only host need not have. `--store-path` switches the locally
built closure without evaluating or building on dot.

Keep current and known-good generation roots. Five GRUB entries are retained.
No automatic GC runs. Do not delete the generation you intend to cold-boot.
From LISH, select the previous generation in GRUB, boot it and verify new SSH,
console login and persistent state. If a switch damages networking, use root
console/password to switch the recorded known-good closure. A failed root mount
requires provider rescue, not wishful use of a login prompt.

**Repair is not installation. No formatting.** Boot the retained installer disk
or provider rescue with newly verified mappings and fingerprints. Prefer the
NixOS installer for Nix tools. If rescue mapping differs from `/dev/sda`, restore
that mapping in the installer profile before using the generated mount script.
Read `lsblk -f`, compare UUIDs/profile disk IDs and check Btrfs before any write.
Do not run `diskoScript`, `--mode disko`, `--mode format`, `btrfs check --repair`
or the new-install phase sequence on a recoverable disk.

Operator recovery command template, authenticated installer SSH as in step 4:

```sh
MOUNT=$(nix build .#nixosConfigurations.dot.config.system.build.mountScript --no-link --print-out-paths)
SYSTEM=$(nix build .#nixosConfigurations.dot.config.system.build.toplevel --no-link --print-out-paths)
export NIX_SSHOPTS="-F /dev/null -i $BOOTSTRAP_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$KNOWN_HOSTS"
nix copy --to "ssh://root@$PUBLIC_IP" "$MOUNT"
# MOUNT is mount-only Disko. Confirm /dev/sda is the existing system disk first.
"${SSH[@]}" "root@$PUBLIC_IP" "set -e; '$MOUNT'; findmnt -R /mnt; lsblk -f"
nix copy --to "ssh://root@$PUBLIC_IP?remote-store=local%3Froot=%2Fmnt" "$SYSTEM"
"${SSH[@]}" "root@$PUBLIC_IP" \
  "nixos-install --root /mnt --no-root-passwd --no-channel-copy --system '$SYSTEM'"
```

This explicit Disko mount plus `nixos-install` repairs generation/GRUB state
without repartitioning. If only the key/hash was lost, recover and stage those
files at `/mnt/mnt/main/storage/...` over authenticated SSH, preserve the
machine-id and reinstall as above. Repeat step 8 before explicit final-profile
boot. Run offline read-only checks or restore from backup rather than guessing
repair flags.

For an entire storage restore, keep the guest stopped. Authenticate the installer
again and verify the actual system Btrfs partition. Do not replace mounted live
storage. Command template, installer console, before mount-only Disko:

```sh
set -euo pipefail
: "${LINODE_ID:?Verify the stopped guest and current installer belong to dot}"
: "${SYSTEM_DISK_ID:?Verify the current mapping of the system disk}"
: "${MAIN_DEVICE:?Set the verified existing Btrfs partition from lsblk}"
lsblk -f "$MAIN_DEVICE"
test "$(blkid -s TYPE -o value "$MAIN_DEVICE")" = btrfs
# If step 11 mounted /mnt already, unmount it before doing this restore.
mkdir -p /mnt/dot-repair
mount -t btrfs -o subvolid=5 "$MAIN_DEVICE" /mnt/dot-repair
btrfs subvolume list /mnt/dot-repair
mkdir -m700 /mnt/dot-repair/incoming
```

Backup host: set `SSH` to a new host-key-checked root installer connection as in
step 4, with the temporary public login key authorized on that installer. Use
actual `PUBLIC_IP`, never a stale tail IP for the stopped guest. Transfer the
verified backup over that authenticated connection:

```sh
: "${PUBLIC_IP:?Set the verified installer public IP}"
: "${BACKUP_DIR:?Set the protected Btrfs backup directory}"
: "${SNAPSHOT:?Set the previously verified storage snapshot name}"
[[ "$SNAPSHOT" =~ ^storage\.[0-9]{8}T[0-9]{4}$ ]]
set -o pipefail
sudo btrfs send "$BACKUP_DIR/$SNAPSHOT" | \
  "${SSH[@]}" "root@$PUBLIC_IP" 'btrfs receive /mnt/dot-repair/incoming'
```

Installer console: verify the received key/hash/ID, then explicitly choose to
replace storage. This replaces persistent account/Tailscale state but does not
format a disk. Keep the old storage for rollback:

```sh
: "${SNAPSHOT:?Set the verified received storage snapshot name}"
[[ "$SNAPSHOT" =~ ^storage\.[0-9]{8}T[0-9]{4}$ ]]
TOP=/mnt/dot-repair
test -s "$TOP/incoming/$SNAPSHOT/etc/machine-id"
ssh-keygen -lf "$TOP/incoming/$SNAPSHOT/etc/ssh/ssh_host_ed25519_key"
test -s "$TOP/incoming/$SNAPSHOT/etc/dot/recovery.hash"
read -r -p 'Type RESTORE-DOT to replace stopped persistent state: ' confirmation
test "$confirmation" = RESTORE-DOT
OLD_STORAGE="$TOP/storage.before-restore.$(date +%Y%m%dT%H%M%S)"
test ! -e "$OLD_STORAGE"
mv "$TOP/storage" "$OLD_STORAGE"
btrfs subvolume snapshot "$TOP/incoming/$SNAPSHOT" "$TOP/storage"
# A failed root reset may have removed only the disposable root subvolume.
if ! test -e "$TOP/root"; then btrfs subvolume create "$TOP/root"; fi
sync
umount "$TOP"
rmdir "$TOP"
```

Now run step 11's mount-only Disko and explicit `nixos-install`, without
`--extra-files`, which would overwrite the recovered identity. Keep old storage
and the received snapshot until validation passes. Space permitting, remove
those specific subvolumes later after another off-host backup; do not delete
snapshots by an unreviewed glob. This same procedure restores storage on an
authorized replacement after its new-disk install and before first boot.

**Lost-instance replacement:** shut down/fence the old instance and preserve
provider records. Obtain a separate explicit paid replacement mandate. Create a
new empty `dot` with new recorded IDs/IPs, repeat steps 1-8 and restore only its
last verified storage backup before first boot. Reuse the original host key,
hash and machine-id when restoring old state. If no backup exists, recover the
key from the original root, generate a fresh console hash and machine-id, and
re-enrol Tailscale. Remove/fence the stale tail node first. Update zone data with
the actual replacement address; never copy sol's address. Verify SSH fingerprint,
console, Tailscale, second reboot, backups and rollback again.

**Independent host-key rotation:** prepare a new dot-only key on the trusted
operator, save its recovery metadata offline, and add its public key to operator
known-hosts before changing the running host. Retain the old key/known-good
closure for console-assisted rollback. Update dot's public key file, rekey any
specific future service secrets to that recipient, build locally, securely stage
the matching private key in persistent storage and switch while console is open.
The identity guard prevents SSH starting with a mismatched key. A one-key change
needs a maintenance window; do not pretend this is fleet dual-key rotation.
Test new SSH/agenix activation, second boot and recovery, then revoke the old key.
Do not remove `fleet-root-independent` to make the broad generator do this.

Public services/DNS are later work. For any future `*.suderman.org` endpoint,
review Traefik's generated router, public visibility, TLS resolver, DNS, firewall
and actual outside-client result separately. `public = true` alone does not
select public TLS policy. Nothing in this host publishes a service.

### 12. Cleanup and retain recovery records

After recording a successful second boot, cold rollback and sample restore,
remove temporary installer/rescue authorization, SSH runtime overrides and any
rescue ISO download. They are disposable installer state, not final host keys.
Close every SSH forward and remove private staging, temporary known-hosts copies
and login credentials from the operator. Keep final verified known-host entries
in the normal operator SSH configuration and store only public provider metadata
in this README. Keep password/seed/backup credentials in protected recovery storage.

Operator:

```sh
if [[ -n ${TUNNEL_PID-} ]]; then kill "$TUNNEL_PID" 2>/dev/null || true; fi
: "${WORK:?Set the private temporary bootstrap directory created in step 1}"
[[ "$(basename "$WORK")" = dot-bootstrap.* ]]
test -d "$WORK" && test "$(stat -c %u "$WORK")" = "$(id -u)"
rm -rf -- "$WORK"
unset HOST_KEY RECOVERY_HASH MACHINE_ID BOOTSTRAP_KEY NIX_SSHOPTS
agenix lock # Only if you unlocked operator master identities for specific secrets.
```

Deletion is not secure erasure on SSD/Btrfs. Use encrypted operator storage for
staging from the start. Do not remove supplied repository/task material.
Optionally delete/reclaim installer resources later with a separately reviewed
provider disk-growth procedure. Preserve a verified external recovery ISO route.

## Local validation and helpers

Run from the repository devshell. `test-identity-scope.py` runs the wrapper's
actual host generation loop with inert stubs and checks the rotation scanner.
`vm-fixture.nix` uses public dummy keys/password/ciphertext, never production
private identity. `test-vm.sh` builds that fixture with the checkout's lockfile;
`test-vm.py` installs it into a private sparse temporary disk through the pinned
tool and authenticated SSH tunnel, then BIOS-boots it with 2 GiB RAM. Ports
22281-22283 must be unused and `/dev/kvm` writable. No physical disks or real
provider are touched. Test temporary disks, keys, tunnels and processes are
removed even on failure. Dummy fixture credentials may be in the Nix store;
production credentials may not.

```sh
nix develop --command python3 hosts/dot/test-identity-scope.py
nix develop --command bash hosts/dot/test-vm.sh
nix develop --command nix build .#checks.x86_64-linux.identity-rotation --no-link -L
```

Use the Git-filtered flake reference above. A `path:.` reference also copies
ignored operator files and can fail on unrelated unreadable scratch directories.
Do not change their permissions to make a validation command pass.

`backup-send.sh` is the host-specific restricted backup source command, installed
only when an approved public backup key is configured. It has no destination
credential. No general cloud orchestrator or custom interactive installer is
added. The existing interactive disk picker is not part of this supported route.

### Evidence and remaining gates

Local results on 2026-10-04, working patch based on `49b128f6`:

- Evaluation/build: dot system, Disko destructive script and mount-only script
  built with root nixpkgs `774debe7a0d1b496e35677ad955a1011c6ff74f3` and Disko
  `725ea35e410ad83be4931d1bff7e090eacaf3563`. Production closure is 1.4 GiB.
  Effective secrets are empty, host identity path matches the table, GRUB device
  is only `/dev/sda`, forceInstall is false, and serial/emergency access is on.
  All eight existing non-ISO hosts evaluate. Identity scope regression and the
  rotation simulation/artifact/finalization check pass. All 27 Bash blocks parse;
  touched-file formatting and whitespace checks pass.
- Disposable BIOS VM: pinned 1.13.0 installation through a host-key-checked
  outer tunnel passes with real `--extra-files` injection of dummy key/hash/ID
  and an agenix probe. The installer is a QEMU fixture declaring
  `VARIANT_ID=installer`, not the standard release ISO. It uses prebuilt fixture
  store paths; production dot was built separately on the operator.
  Verified BIOS GRUB interaction, password serial login, strict SSH identity,
  agenix activation, root reset, persistent account/home/Tailscale-directory state
  and previous-boot logs. Restricted backup pull/restore matches key/hash/ID;
  shell/path-injection attempts fail. Missing backup acknowledgement fails health
  checking; a verified-send acknowledgement passes it. Remote closure switch,
  runtime rollback, three cold boots and mount-only Disko plus `nixos-install`
  repair all pass. Installed guest has 2 GiB RAM; idle memory was about 297 MiB,
  one generation used 52 MiB of `/boot`, and Btrfs used about 992 MiB on the
  16 GiB test disk. These are fixture measurements, not provider guarantees.
- Real provider: no authenticated provider access, instance creation, disk write,
  deployment or service publication. Public catalog reads are not commissioning.
  Standard release ISO download/write, actual disk/profile mapping, Direct Disk
  boot, LISH, dual-stack networking, Tailscale enrolment/reboot, real remote updates,
  backup destination and replacement restore await an explicit deployment mandate.

Repository evaluation/build, disposable-VM validation and real-provider
commissioning are distinct. VM success is not evidence of provider results.
The command templates and pinned tool flags were checked locally; a complete
empty-Linode walkthrough cannot be tested without the authorized instance.

Remaining decisions are workload, plan/current price, final region, acceptance
of this concrete host-only trust policy, backup host/encrypted destination and
future public domains. Hostname `dot` is settled.

References: [Direct Disk semantics](https://techdocs.akamai.com/cloud-computing/docs/manage-the-kernel-on-a-compute-instance),
[custom distribution installation](https://www.akamai.com/cloud/guides/install-a-custom-distribution/),
[network configuration](https://techdocs.akamai.com/cloud-computing/docs/manual-network-configuration-on-a-compute-instance),
[backup limits](https://techdocs.akamai.com/cloud-computing/docs/troubleshooting-issues-with-the-backup-service),
[nixos-anywhere 1.13.0 source](https://github.com/nix-community/nixos-anywhere/blob/1.13.0/src/nixos-anywhere.sh).
