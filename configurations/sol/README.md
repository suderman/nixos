# sol

Linode VPS for public web services. This instance is running the Linode 2 GB plan in the Toronto, ON region.

## Installation

<details>

<summary><b>1. Provision server</b></summary>

Create new server named `sol` via [Linode dashboard](https://cloud.linode.com/linodes). Also, ensure the `linode-cli` command is available and logged in on your laptop. Run the command a provide a [Personal Access Token](https://cloud.linode.com/profile/tokens) if prompted.

```bash
linode-cli linodes create –label sol
–region ca-central
–type g6-nanode-1
–root_pass
–booted true
–backups_enabled false
–private_ip false
```

</details>
<details>

<summary><b>2. Create disks & profiles</b></summary>

We need to install the [min](https://github.com/suderman/nixos/tree/main/configurations/min) configuration as a starting point. Using your laptop, run the [nixos linode]([https://github.com/suderman/nixos/blob/main/configurations/min/linode.sh](https://github.com/suderman/nixos/blob/main/overlays/pkgs/nixos-cli/src/linode_command.sh)) script found in this repo:

```bash
nixos linode
```

Choose the `00000000_sol` linode from the menu and follow the wizard. After confirmation, it will power off the chosen linode, destroy any existing disks & configurations, and create the following:

### Two disks under Storage tab:

| Label     | Type    | Size  | Device   |
| --------- | ------- | ----- | -------- |
| installer | ext4    | 1024M | /dev/sdb |
| nixos     | raw     | -     | /dev/sda |


### Two configuration profiles under Configurations tab:

| Label     | Kernel      | /dev/sda | /dev/sdb  | Root Device |
| --------- | ----------- | -------- | --------- | ----------- |
| installer | Direct Disk | nixos    | installer | /dev/sdb    |
| nixos     | Direct Disk | root     | -         | /dev/sda    |

*All Filesystem/Boot Helpers disabled!*

</details>
<details>

<summary><b>3. Create NixOS installer</b></summary>

Next, the wizard will launch a Weblish console with the Linode booted in Rescue mode. Paste the following into the console to [download](https://nixos.org/download.html) the latest NixOS ISO and write it to `/dev/sdb`:

```bash
# https://nixos.org/download.html
iso=https://channels.nixos.org/nixos-22.11/latest-nixos-minimal-x86_64-linux.iso

# Download the ISO, write it to the installer disk, and verify the checksum:
curl -L $iso | tee >(dd of=/dev/sdb) | sha256sum
```

When finished, type `y` on the other computer to continue.

</details>
<details>

<summary><b>4. Install NixOS</b></summary>

Next, the wizard will launch a Glish console with the Linode booted using the `installer` profile. First type `sudo -s` into the console, and then paste the following bash command:

```bash
sudo -s
bash <(curl -sL https://github.com/suderman/nixos/raw/main/overlays/pkgs/nixos-cli/nixos) bootstrap linode
```

When finished, type `y` on the other computer to continue.

</details>
<details>

<summary><b>5. Rekey secrets</b></summary>

After the Linode boots using the `nixos` profile, the laptop will keyscan the new host. Then repo's secrets will be updated with Linode's public key and all the secrets rekeyed. Commit these changes and `git push`:

```bash
cd /etc/nixos
git commit -m rekey
git push
```
 
</details>
<details>
 
<summary><b>6. Switch configurations</b></summary>

Using the Weblish console, login to the Linode as root (with password "root"). Then finish the install with `nixos bootstrap switch sol`. This will pull in the rekeyed secrets from git, move min's generated `hardware-configuration.nix` to sol, and run `nixos-rebuild switch`. 

```bash
nixos bootstrap switch sol
```

Once finished, the system will reboot. Login as a regular user. Commit the generated `hardware-configuration.nix` and `git push` to the repo.

</details>
<details>

<summary><b>7. Configure Tailscale</b></summary>

If this machine previously existed in the Tailnet, first login to [Tailscale](https://login.tailscale.com/admin/machines) and remove the old entry. Then enter the following commands to login to Tailscale and update our DNS records:

```bash
sudo tailscale up
sudo systemctl start tailscale-dns
```
</details>
