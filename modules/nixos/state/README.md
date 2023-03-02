# State configuration for NixOS hosts

Use [impermanence](https://github.com/nix-community/impermanence) to mount
or link certain directories and files in `/nix/state`:

## Directories

- `/etc/nixos`
- `/etc/NetworkManager/system-connections`
- `/var/lib`
- `/var/log`  
- `/home`

## Files

- `/etc/machine-id`
- `/etc/ssh/ssh_host_ed25519_key`
- `/etc/ssh/ssh_host_rsa_key`

## Usage

Enable module in configuration like so:

```nix
{
  state.enable = true;
}
```

Additional directories and files can be added in the configuration like so:

```nix
{
  state.dirs = [ "/var/www" ];
  state.files = [ "/etc/passwd" ];
}
```

## Resources
- <https://grahamc.com/blog/erase-your-darlings>
- <https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/>
- <https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html>
