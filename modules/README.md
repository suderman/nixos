# NixOS & Home Manager modules

Each of these directories are included via
[numtide's blueprint](https://numtide.github.io/blueprint/main/getting-started/folder_structure/)
and available under `flake.nixosModules.*` and `flake.homeModules.*`. The
`flake.nixosModules.default` module should be imported into every `host`
configuration and includes shared NixOS configuration and custom module options.
The `flake.homeModules.default` module should be imported into every `home`
configuration and includes shared home-manager configuration and custom module
options.
