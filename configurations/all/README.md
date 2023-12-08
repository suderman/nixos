# Configuration shared by all NixOS systems

Common defaults I like to use for each system:

## Network

- Enable firewall 
- Set host & domain names
- Disable IPv6

## Nix

- Enable experimental features and flakes support
- Automatic garbage collection 
- Automatic system upgrades

## Packages

- Basic tooling I always want available (git, curl, vim, etc)
- zsh and bash completions

## Sudo

- Password settings for sudo users

## Users

- Immutable users
- root, user and test accounts
- Use password from secrets
- Set ssh public key

## State configuration for NixOS systems

Use [impermanence](https://github.com/nix-community/impermanence) to mount
or link certain directories and files in `/nix/state`:

### Directories

- `/etc/nixos`
- `/etc/NetworkManager/system-connections`
- `/var/lib`
- `/var/log`  
- `/home`

### Files

- `/etc/machine-id`
- `/etc/ssh/ssh_host_ed25519_key`
- `/etc/ssh/ssh_host_rsa_key`

### Usage

Additional directories and files can be added in the configuration like so:

```nix
{
  config.this.dirs = [ "/var/www" ];
  config.this.files = [ "/etc/passwd" ];
}
```

### Resources
- <https://grahamc.com/blog/erase-your-darlings>
- <https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/>
- <https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html>
