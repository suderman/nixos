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
    target = storage / "etc/ssh/ssh_host_ed25519_key"
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(f"{fixtures}/host", target)
    target.chmod(0o600)
    shutil.copytree(f"{fixtures}/agents", storage / "home/jon/.agents")
    run("chmod", "-R", "u+w", str(storage / "home/jon"))
    stage.chmod(0o700)
    run("qemu-img", "create", "-f", "qcow2", "system.qcow2", "32G")
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
                ssh + ["-p", "22281", "root@127.0.0.1", "true"],
                capture_output=True,
                check=False,
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
            "--chown",
            "/mnt/main/storage/home/jon",
            "1000:100",
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
            guest.expect("root@dot:")
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
            "set -e; systemctl is-active sshd tailscaled; "
            'test "$(systemctl show --value -p Result sshed)" = success; '
            'test "$(systemctl show --value -p Result home-manager-jon)" = success; '
            "test \"$(stat -Lc '%U %G %a' /run/agenix/hex)\" = 'root root 400'"
        )
        print(host("free -m; df -h /boot /mnt/main; systemctl --failed --no-pager"))
        # Starting the real user secret unit verifies the derived age identity.
        user_secret = run(
            *ssh,
            "-p",
            "22282",
            "jon@127.0.0.1",
            "systemctl --user start agenix && cat /run/user/1000/agenix/gh-token",
            capture_output=True,
        ).stdout
        assert user_secret.strip() == "dot-test-secret"
        assert (
            host("cat /run/agenix/hex").strip()
            == Path(fixtures, "root.hex").read_text().strip()
        )
        # Re-activate after persistence mounts, as on a fresh normal fleet install.
        host(f"nixos-rebuild switch --no-reexec --store-path {system}")
        host("cmp /mnt/main/storage/home/jon/.ssh/id_ed25519 /home/jon/.ssh/id_ed25519")
        assert host("cat /run/agenix/dot-vm-probe").strip() == "dot-test-secret"
        machine = host("cat /etc/machine-id").strip()
        assert machine == Path(fixtures, "machine-id").read_text().strip()
        host(
            "set -e; touch /dot-ephemeral /home/jon/.ssh/dot-home /var/lib/nixos/dot-state "
            "/var/lib/tailscale/dot-state; logger dot-vm-first-boot; "
            "systemctl start btrbk-snapshots; btrfs subvolume list /mnt/main"
        )
        snapshot = host(
            "find /mnt/main/snapshots -maxdepth 1 -type d -name 'main.*' | sort | tail -n1"
        ).strip()
        assert snapshot.startswith("/mnt/main/snapshots/main.")
        # Exercise the normal fleet's restricted btrbk account.
        backup_key = work / "btrbk"
        shutil.copyfile(f"{fixtures}/users/btrbk/id_ed25519", backup_key)
        backup_key.chmod(0o600)
        backup = ssh.copy()
        backup[backup.index(str(key))] = str(backup_key)
        for command in ("id", f"sudo -n btrfs send {snapshot}; id"):
            assert (
                subprocess.run(
                    backup + ["-p", "22282", "btrbk@127.0.0.1", command],
                    capture_output=True,
                    check=False,
                ).returncode
                != 0
            )
        stream = subprocess.run(
            backup
            + ["-p", "22282", "btrbk@127.0.0.1", f"sudo -n btrfs send {snapshot}"],
            check=True,
            capture_output=True,
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
            "set -e; cmp /mnt/main/storage/etc/ssh/ssh_host_ed25519_key "
            "/mnt/main/scratch/restore/*/etc/ssh/ssh_host_ed25519_key; "
            "test -e /mnt/main/scratch/restore/*/home/jon/.ssh/dot-home; "
            "btrfs subvolume delete /mnt/main/scratch/restore/*; rmdir /mnt/main/scratch/restore"
        )
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
            "set -e; test ! -e /dot-ephemeral; test -e /home/jon/.ssh/dot-home; "
            "test -e /var/lib/nixos/dot-state; test -e /var/lib/tailscale/dot-state; "
            "test ! -e /etc/dot-vm-generation; journalctl --no-pager -b -1 | grep dot-vm-first-boot; "
            "systemctl is-active sshd tailscaled; "
            'test "$(systemctl show --value -p Result sshed)" = success; '
            'test "$(systemctl show --value -p Result home-manager-jon)" = success'
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
        host("test -e /home/jon/.ssh/dot-home && test -e /var/lib/tailscale/dot-state")
        print(
            "PASS: authenticated tunnel, destructive dummy install, BIOS GRUB, password serial login,"
        )
        print(
            "fleet root and user agenix activation, derived identities, Home Manager persistence/logs,"
        )
        print(
            "normal btrbk access/restore, root reset, rollback, repeat cold boots and mount-only repair (2 GiB RAM)."
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
