# cog

Framework laptop

## Update secrets/keys.nix

To access encrypted secrets, each host needs an SSH Host key's public key
included in [secrets/keys.nix](https://github.com/suderman/nixos/blob/main/secrets/keys.nix). 
To update a host key, generate a new key from existing host in the network.

```bash
# Generate private key (this will be transfered to new host later)
ssh-keygen -q -N "" -t ed25519 -f ssh_host_ed25519_key

# Copy public key
cat ssh_host_ed25519_key.pub | wl-copy 
```

Update the line with `cog = "ssh-ed25519 AAA...` using the new public key on the clipboard. 
Then rekey all the secrets, commit and push the git repo.

```bash
# Rekey the secrets/*.age files to include the new host key
RULES=/etc/nixos/secrets/secrets.nix agenix --rekey

# Commit changes and push repo
cd /etc/nixos && git commit -am "Updated host key" && git push
```

Prepare to transfer private key to host, either via USB or Magic Wormhole.

```bash
# Create shell with (rust version of) Magic Wormhole available
nix-shell -p magic-wormhole-rs

# Initiate transfer
wormhole-rs send ssh_host_ed25519_key
```

## Boot NixOS installer

<https://nixos.org/download.html>
