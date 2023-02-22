# sol

Linode VPS for public web services.

## Installation

<details>

<summary><b>1. Create server via Linode dashboard</b></summary>

Create new server named `sol` via [Linode dashboard](https://cloud.linode.com/linodes). Also, ensure the `linode-cli` command is available and logged in on the other computer. Run the command a provide a [Personal Access Token](https://cloud.linode.com/profile/tokens) if prompted.

```bash
linode-cli
```

</details>
<details>

<summary><b>2. Run linode.sh script</b></summary>

We need to install the [min](https://github.com/suderman/nixos/tree/main/configurations/min) configuration as a starting point. Using the other computer, run the [linode.sh](https://github.com/suderman/nixos/blob/main/configurations/min/linode.sh) script found in this repo:

```bash
/etc/nixos/configurations/min/linode.sh
```

Choose the `00000000_sol` linode from the menu and follow the wizard. After confirmation, it will power off the chosen linode, destroy any existing disks & configurations, and create the following:

### Four disks under Storage tab:

| Label  | Type    | Size  | Device   |
| ------ | ------- | ----- | -------- |
| iso    | ext4    | 1024M | /dev/sdd |
| root   | ext4    | 1024M | /dev/sda |
| swap   | swap    | 2048M | /dev/sdb |
| nix    | raw     | -     | /dev/sdc |


### Two configuration profiles under Configurations tab:

| Label     | Kernel      | /dev/sda | /dev/sdb | /dev/sdc | /dev/sdd | Root Device |
| --------- | ----------- | -------- | -------- | -------- | -------- | ----------- |
| installer | Direct Disk | root     | swap     | nix      | iso      | /dev/sdd    |
| nixos     | GRUB 2      | root     | swap     | nix      | -        | /dev/sda    |

*All Filesystem/Boot Helpers disabled!*

</details>
<details>

<summary><b>3. Create NixOS installer</b></summary>

Next, the wizard will launch a Weblish console with the Linode booted in Rescue mode. Paste the following into the console to [download](https://nixos.org/download.html) the latest NixOS ISO and write it to `/dev/sdd`:

```bash
# https://nixos.org/download.html
iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso

# Download the ISO, write it to the installer disk, and verify the checksum:
curl -L $iso | tee >(dd of=/dev/sdd) | sha256sum
```

When finished, type `y` on the other computer to continue.

</details>
<details>

<summary><b>4. Install NixOS</b></summary>

Next, the wizard will launch a Glish console with the Linode booted using the `installer` profile. First type `sudo -s` into the console, and then paste the following bash command:

```bash
sudo -s
bash <(curl -sL https://github.com/suderman/nixos/raw/main/configurations/min/install.sh) LINODE
```

When finished, type `y` on the other computer to continue.

</details>
<details>

<summary><b>5. Switch configurations</b></summary>

Next, the wizard will launch a Weblish console with the Linode booted using the `nixos` profile. Login as a regular user (with matching password).

On the other computer, the repo's secrets will be updated with Linode's public key and all the secrets rekeyed. Commit these changes to and `git push`:

```bash
 cd /etc/nixos
 git commit -m rekey
 git push
```

On the Linode Weblish console, `git pull` changes in this repo and run the `nixos-rebuild switch` command. Then exit and login again.

```bash
 cd /etc/nixos
 git pull
 sudo nixos-rebuild switch
 exit
```

Head back into `/etc/nixos` repo and move the generated `hardware-configuration.nix` into this configuration's directory. Then restore the [min](https://github.com/suderman/nixos/tree/main/configurations/min) configuration to how it was before. Finally, run `nixos-rebuild switch` to change into this configuration:

```bash
cd /etc/nixos
mv -f configurations/min/hardware-configuration.nix configurations/sol/hardware-configuration.nix
git restore configurations/min

# Finally!
sudo nixos-rebuild switch --flake /etc/nixos#sol
```

Reboot to ensure everything worked. Commit the generated `hardware-configuration.nix` and `git push` to the repo.
</details>
