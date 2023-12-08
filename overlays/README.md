# Nixpkgs Overlays

Extend `pkgs` with my customizations and additions. Organized into
[pkgs](https://github.com/suderman/nixos/tree/main/overlays/pkgs),
[bin](https://github.com/suderman/nixos/tree/main/overlays/bin), and
[lib](https://github.com/suderman/nixos/tree/main/overlays/lib). 

## pkgs

Additional packages and tweaks to existing packages. Every
`overlays/pkgs/*.nix` and `overlays/pkgs/*/default.nix` gets automatically
imported into `pkgs.*` inheriting an attribute name from the file or directory.
The `overlays/pkgs/default.nix` is also imported and may contain many package
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
[here](https://github.com/suderman/nixos/blob/main/default.nix#L9)). Every
`overlays/lib/*.nix` and `overlays/lib/*/default.nix` gets automatically
imported into `pkgs.this.lib.*` inheriting an attribute name from the file or
directory. The `overlays/lib/default.nix` file is also imported and may contain
many lib functions in that one file.
