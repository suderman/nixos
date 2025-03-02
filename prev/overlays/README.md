# Nixpkgs Overlays

Extend `pkgs` with my customizations and additions. Organized into
[pkgs](https://github.com/suderman/nixos/tree/main/overlays/pkgs),
[bin](https://github.com/suderman/nixos/tree/main/overlays/bin),
[lib](https://github.com/suderman/nixos/tree/main/overlays/lib), and
[hardware](https://github.com/suderman/nixos/tree/main/overlays/hardware). 

## mods

Overrides to existing packages. Every `overlays/mods/*.nix` and
`overlays/mods/*/default.nix` gets automatically imported into `pkgs.*`
inheriting an attribute name from the file or directory. The
`overlays/mods/default.nix` is also imported and may contain many package
extensions in that one file.

## pkgs

Additional packages missing from nixpkgs. Every `overlays/pkgs/*.nix` and
`overlays/pkgs/*/default.nix` gets automatically imported into `pkgs.*`
inheriting an attribute name from the file or directory. The
`overlays/pkgs/default.nix` is also imported and may contain many package
extensions in that one file.

## bin

Works the same as above, but this is specifically for command line utilities
and personal shell scripts. Every `overlays/bin/*.nix` and
`overlays/bin/*/default.nix` gets automatically imported into `pkgs.*`
inheriting an attribute name from the file or directory. The
`overlays/bin/default.nix` is also imported and may contain many package
extensions in that one file.

## lib

Extends the `pkgs.this.lib` library (which begins early in my flake
[here](https://github.com/suderman/nixos/blob/main/this.nix#L6)). Every
`overlays/lib/*.nix` and `overlays/lib/*/default.nix` gets automatically
imported into `pkgs.this.lib.*` inheriting an attribute name from the file or
directory. The `overlays/lib/default.nix` file is also imported and contains
additional lib functions in that one file. At configuration, `pkgs.this.lib` 
is merged with `pkgs.lib` as `lib` in `specialArgs` and `extraSpecialArgs`. 

## hardware

Additional hardware configurations. Every `overlays/hardware/*.nix` and
`overlays/hardware/*/default.nix` gets automatically imported into `pkgs.*`
inheriting an attribute name from the file or directory. The 
[nixos-hardware](https://github.com/suderman/nixos/blob/main/flake.nix#L27) 
input is also merged into this attribute set, and included in `specialArgs` 
at configuration.
