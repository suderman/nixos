# NixOS host configurations

Each of these directories is included via
[numtide's blueprint](https://numtide.github.io/blueprint/main/getting-started/folder_structure/)
and available under `flake.nixosConfigurations.*`. NixOS configuration files can
be found in `hosts/<hostname>/configuration.nix` and
host-specific Home Manager configurations can be found in
`hosts/<hostname>/users/<username>.nix` or
`hosts/<hostname>/users/<username>/home-configuration.nix`.

New hosts are added using this flake's default package:

```sh
nixos add host
```

## My current list

- `cog`
  [Framework laptop](https://github.com/suderman/nixos/tree/main/hosts/cog) ⚙
- `eve`
  [2009 Mac Pro (at work)](https://github.com/suderman/nixos/tree/main/hosts/eve)
  🌒
- `hub`
  [Intel NUC home server](https://github.com/suderman/nixos/tree/main/hosts/hub)
  ️🏚️
- `kit`
  [2024 FormD T1 desktop](https://github.com/suderman/nixos/tree/main/hosts/kit)
  🎮
- `lux`
  [Intel NUC media server](https://github.com/suderman/nixos/tree/main/hosts/lux)
  🎬
- `pow`
  [2009 Mac Pro (at home)](https://github.com/suderman/nixos/tree/main/hosts/pow)
  👟
- `sim`
  [NixOS test VM](https://github.com/suderman/nixos/tree/main/hosts/sim)
- `wit`
  [Thinkpad T480s laptop](https://github.com/suderman/nixos/tree/main/hosts/wit)
  💻
- `iso`
  [Custom NixOS installer ISO](https://github.com/suderman/nixos/tree/main/hosts/iso)
  💿
