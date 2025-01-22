# NixOS & Home Manager modules

Each of these directories are automatically imported in each configuration.

Every subdirectory with `nixos.nix` represents a module for NixOS and
`home.nix` represents a module for Home Manager. Some of these are custom
modules while others are opinionated overrides of existing nixpkgs modules.
Each module must be opted-in using the enable option.

## Example

```nix
{
  config.programs.neovim.enable = true;
}
```

This can be done in `configuration.nix` for NixOS modules and `home.nix` for
Home Manager modules.
