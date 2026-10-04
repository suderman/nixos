#!/usr/bin/env python3
"""Install dot into a temporary BIOS VM. All credentials come from vm-fixture.nix."""

import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import pexpect

paths = json.loads(sys.argv[1])
fixtures, system, second, disko, mount, installer, tools = (
    paths[name]
    for name in ("fixtures", "system", "second", "disko", "mount", "installer", "tools")
)
os.environ["PATH"] = f"{tools}/bin:" + os.environ["PATH"]


def run(*args, **kwargs):
    return subprocess.run(args, check=True, text=True, **kwargs)


for port in (22281, 22282, 22283):
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", port))

with (
    tempfile.TemporaryDirectory(prefix="dot-bios-test-") as temporary,
    open(Path(temporary) / "serial.log", "w") as serial_log,
):
    work = Path(temporary)
    os.chdir(work)
    key = work / "client"
    shutil.copyfile(f"{fixtures}/client", key)
    key.chmod(0o600)
    known = work / "known_hosts"
    known.write_text(
        "".join(
            f"[127.0.0.1]:{port} {Path(fixtures, name + '.pub').read_text()}"
            for port, name in ((22281, "installer"), (22282, "host"))
        )
    )
    ssh = [
        "ssh",
        "-F",
        "/dev/null",
        "-i",
        str(key),
        "-o",
        "IdentitiesOnly=yes",
        "-o",
        "BatchMode=yes",
        "-o",
        "StrictHostKeyChecking=yes",
        "-o",
        f"UserKnownHostsFile={known}",
    ]
    stage = work / "stage"
    storage = stage / "mnt/main/storage"
    for name, destination in (
        ("host", "etc/ssh/ssh_host_ed25519_key"),
        ("recovery.hash", "etc/dot/recovery.hash"),
        ("machine-id", "etc/machine-id"),
    ):
        target = storage / destination
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(f"{fixtures}/{name}", target)
        target.chmod(0o600 if name != "machine-id" else 0o444)
    stage.chmod(0o700)
    run("qemu-img", "create", "-f", "qcow2", "system.qcow2", "16G")
    vm = None
    tunnel = None
    try:
        installer_env = os.environ | {"TMPDIR": str(work), "USE_TMPDIR": "1"}
        vm = pexpect.spawn(
            f"{installer}/bin/run-dot-installer-test-vm",
            env=installer_env,
            encoding="utf-8",
            timeout=300,
        )
        vm.logfile_read = serial_log
        vm.expect("login:")
        vm.sendline("root")
        vm.expect(r"]#")
        vm.sendline("ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key")
        fingerprint = run(
            "ssh-keygen", "-lf", f"{fixtures}/installer.pub", capture_output=True
        ).stdout.split()[1]
        vm.expect_exact(fingerprint)
        for _ in range(60):
            probe = subprocess.run(
                ssh + ["-p", "22281", "root@127.0.0.1", "true"], capture_output=True
            )
            if probe.returncode == 0:
                break
            time.sleep(1)
        else:
            raise RuntimeError("installer SSH did not start")
        tunnel = subprocess.Popen(
            ssh
            + [
                "-p",
                "22281",
                "-N",
                "-o",
                "ExitOnForwardFailure=yes",
                "-L",
                "127.0.0.1:22283:127.0.0.1:22",
                "root@127.0.0.1",
            ]
        )
        time.sleep(1)
        assert tunnel.poll() is None
        run(
            "nixos-anywhere",
            "--ssh-option",
            "ControlPath=none",
            "--no-substitute-on-destination",
            "--build-on",
            "local",
            "--store-paths",
            disko,
            system,
            "--phases",
            "disko,install",
            "--extra-files",
            str(stage),
            "-i",
            str(key),
            "-p",
            "22283",
            "root@127.0.0.1",
        )
        run(
            *ssh,
            "-p",
            "22281",
            "root@127.0.0.1",
            "test -s /mnt/boot/grub/grub.cfg && "
            "test -s /mnt/mnt/main/storage/etc/ssh/ssh_host_ed25519_key && "
            "test -s /mnt/mnt/main/storage/etc/dot/recovery.hash && "
            "lsblk -f; sync; umount -R /mnt; swapoff -a",
        )
        tunnel.terminate()
        tunnel.wait(timeout=10)
        tunnel = None
        vm.terminate(force=True)
        vm = None

        def start_installed():
            guest = pexpect.spawn(
                "qemu-system-x86_64",
                [
                    "-enable-kvm",
                    "-m",
                    "2048",
                    "-smp",
                    "2",
                    "-display",
                    "none",
                    "-serial",
                    "stdio",
                    "-monitor",
                    "none",
                    "-drive",
                    "file=system.qcow2,format=qcow2,if=ide",
                    "-netdev",
                    "user,id=net0,hostfwd=tcp:127.0.0.1:22282-:22",
                    "-device",
                    "virtio-net-pci,netdev=net0",
                ],
                encoding="utf-8",
                timeout=300,
            )
            guest.logfile_read = serial_log
            guest.expect("GNU GRUB")
            guest.sendline("")
            guest.expect("dot login:")
            guest.sendline("root")
            guest.expect("Password:")
            guest.sendline("dot-test-only")
            guest.expect(r"]#")
            guest.sendline(
                "test \"$(id -u)\" = 0 && printf '\\nDOT_SERIAL_LOGIN_OK\\n'"
            )
            guest.expect(r"\nDOT_SERIAL_LOGIN_OK", searchwindowsize=1024)
            return guest

        def host(command):
            return run(
                *ssh, "-p", "22282", "root@127.0.0.1", command, capture_output=True
            ).stdout

        vm = start_installed()
        host(
            "set -e; systemctl is-active sshd tailscaled; systemctl show --value -p Result dot-identity | grep -qx success"
        )
        print(host("free -m; df -h /boot /mnt/main; systemctl --failed --no-pager"))
        host(
            "if systemctl start dot-health; then exit 1; fi; systemctl reset-failed dot-health"
        )
        assert host("cat /run/agenix/dot-vm-probe").strip() == "dot-test-secret"
        machine = host("cat /etc/machine-id").strip()
        assert machine == "9dbbfc8683d44058b9a2f2f837430168"
        host(
            "set -e; touch /dot-ephemeral /home/jon/dot-home /var/lib/nixos/dot-state "
            "/var/lib/tailscale/dot-state; logger dot-vm-first-boot; "
            "systemctl start btrbk-dot; btrfs subvolume list /mnt/main"
        )
        backup = ssh + ["-p", "22282", "dot-backup@127.0.0.1"]
        snapshot = run(*backup, "list", capture_output=True).stdout.splitlines()[-1]
        for denied in (
            "id",
            "send storage.20000101T000000/../../root",
            "send storage.20000101T000000; id",
        ):
            assert (
                subprocess.run(backup + [denied], capture_output=True).returncode != 0
            )
        # Receive a stream obtained through the restricted backup account, not root SSH.
        stream = subprocess.run(
            backup + [f"send {snapshot}"], check=True, capture_output=True
        ).stdout
        host("mkdir /mnt/main/scratch/restore")
        subprocess.run(
            ssh
            + [
                "-p",
                "22282",
                "root@127.0.0.1",
                "btrfs receive /mnt/main/scratch/restore",
            ],
            input=stream,
            check=True,
        )
        host(
            "set -e; cmp /etc/machine-id /mnt/main/scratch/restore/*/etc/machine-id; "
            "cmp /mnt/main/storage/etc/ssh/ssh_host_ed25519_key /mnt/main/scratch/restore/*/etc/ssh/ssh_host_ed25519_key; "
            "cmp /mnt/main/storage/etc/dot/recovery.hash /mnt/main/scratch/restore/*/etc/dot/recovery.hash; "
            "btrfs subvolume delete /mnt/main/scratch/restore/*; rmdir /mnt/main/scratch/restore"
        )
        run(*backup, "acknowledge", capture_output=True)
        host("systemctl start dot-health")
        env = os.environ.copy()
        env["NIX_SSHOPTS"] = " ".join(ssh[1:] + ["-p", "22282"])
        run("nix", "copy", "--to", "ssh://root@127.0.0.1", second, env=env)
        host(f"nixos-rebuild switch --no-reexec --store-path {second}")
        assert host("cat /etc/dot-vm-generation").strip() == "second"
        host("nixos-rebuild switch --rollback --no-reexec")
        assert (
            host(
                "test ! -e /etc/dot-vm-generation; readlink -f /run/current-system"
            ).strip()
            == system
        )
        host("sync")
        vm.terminate(force=True)
        vm = start_installed()
        host(
            "set -e; test ! -e /dot-ephemeral; test -e /home/jon/dot-home; "
            "test -e /var/lib/nixos/dot-state; test -e /var/lib/tailscale/dot-state; "
            "test ! -e /etc/dot-vm-generation; journalctl --no-pager -b -1 | grep dot-vm-first-boot; "
            "systemctl start dot-health; systemctl is-active sshd tailscaled"
        )
        assert host("cat /etc/machine-id").strip() == machine
        assert host("cat /run/agenix/dot-vm-probe").strip() == "dot-test-secret"
        assert host("readlink -f /run/current-system").strip() == system
        run(
            *ssh,
            "-p",
            "22282",
            "jon@127.0.0.1",
            "sudo -n nixos-rebuild --help",
            capture_output=True,
        )
        # Boot installer again and repair with mount-only Disko, never the format script.
        host("sync")
        vm.terminate(force=True)
        vm = pexpect.spawn(
            f"{installer}/bin/run-dot-installer-test-vm",
            env=installer_env,
            encoding="utf-8",
            timeout=300,
        )
        vm.logfile_read = serial_log
        vm.expect("login:")
        run(
            *ssh,
            "-p",
            "22281",
            "root@127.0.0.1",
            f"set -e; {mount}; nixos-install --no-root-passwd --no-channel-copy --system {system}; "
            "test -e /mnt/mnt/main/storage/var/lib/nixos/dot-state; sync; umount -R /mnt; swapoff -a",
        )
        vm.terminate(force=True)
        vm = start_installed()
        assert host("cat /etc/machine-id").strip() == machine
        assert host("cat /run/agenix/dot-vm-probe").strip() == "dot-test-secret"
        host("test -e /home/jon/dot-home && test -e /var/lib/tailscale/dot-state")
        print(
            "PASS: authenticated tunnel, destructive dummy install, BIOS GRUB, password serial login,"
        )
        print(
            "agenix activation, SSH host identity, persistent state/logs, root reset, snapshot restore,"
        )
        print(
            "restricted backup pull/restore, runtime rollback, repeat cold boots and mount-only repair (2 GiB RAM)."
        )
    except BaseException as error:
        if isinstance(error, subprocess.CalledProcessError):
            print(error.stdout, error.stderr, file=sys.stderr)
        serial_log.flush()
        print(Path("serial.log").read_text()[-14000:], file=sys.stderr)
        raise
    finally:
        if tunnel is not None:
            tunnel.terminate()
            tunnel.wait(timeout=10)
        if vm is not None:
            vm.terminate(force=True)
