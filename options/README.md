# NixOS & Home Manager module presets

Each of these directories are automatically imported in each configuration.

Every subdirectory with `default.nix` represents a preset for NixOS and
`home.nix` represents a preset for Home Manager. All presets must be opted-in
using the enable option.

## Example

```nix
{
  config.programs.neovim.enable = true;
}
```

This can be done in `configuration.nix` for NixOS presets and `home.nix` for
Home Manager presets.
