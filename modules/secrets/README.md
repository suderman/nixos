# Secrets configuration for NixOS

Use [agenix](https://github.com/ryantm/agenix) to encrypt/decrypt
files for use in NixOS configuration. 

## Usage

Enable module in configuration like so:

```nix
{
  modules.secrets.enable = true;
}
```

See `nixos secrets` CLI usage [here](https://github.com/suderman/nixos/tree/main/secrets).
