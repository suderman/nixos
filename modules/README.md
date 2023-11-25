# NixOS & Home Manager Modules

Every subdirectory with `default.nix` represents a module for NixOS and
`home.nix` represents a module for Home Manager. With the exception of the 
[base module](https://github.com/suderman/nixos/tree/main/modules/base), 
which is automatically included in every configuration, all modules must 
be opted-in using the enable option.

## Example

```nix
{
  modules.neovim.enable = true;
}
```

This can be done in `configuration.nix` for NixOS modules and `home.nix` for
Home Manager modules. Alternatively, for any modules which support both NixOS
and Home Manager, you can add the above snippet to `base.nix` and this will
enable the module in both contexts.
