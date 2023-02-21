# Secrets configuration for NixOS hosts

Use the [agenix](https://github.com/ryantm/agenix) to encrypt/decrypt
files for use in NixOS configuration. 

## Usage

Enable module in configuration like so:

```nix
{
  secrets.enable = true;
}
```
