# NixOS & Home Manager Modules

Each of these directories are automatically imported in each configuration.

Every subdirectory with `default.nix` represents a module for NixOS and
`home.nix` represents a module for Home Manager. All modules must be opted-in
using the enable option.

## Example

```nix
{
  config.modules.neovim.enable = true;
}
```

This can be done in `configuration.nix` for NixOS modules and `home.nix` for
Home Manager modules. Alternatively, for any modules which support both NixOS
and Home Manager, you can add the above snippet to a configuration's
`default.nix` and this will enable the module in both contexts.
