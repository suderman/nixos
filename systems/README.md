# NixOS system configurations

The `all` directory contains shared configuration automatically imported in every system below. 

- `all` [Shared system configuration](https://github.com/suderman/nixos/tree/main/systems/all)

Each of these directories are automatically imported and available in my
flake's `outputs.nixosConfigurations.*`. NixOS configuration files can be found in
`systems/*/configuration.nix` and system-specific Home Manager configurations can be found in 
`systems/*/users/*.nix` or `systems/*/users/*/home.nix`

- `bootstrap` [Bootstrap configuration](https://github.com/suderman/nixos/tree/main/systems/bootstrap)
- `cog` [Framework laptop](https://github.com/suderman/nixos/tree/main/systems/cog)
- `eve` [2009 Mac Pro (at work)](https://github.com/suderman/nixos/tree/main/systems/eve)
- `fit` [2009 Mac Pro (at home)](https://github.com/suderman/nixos/tree/main/systems/fit) 
- `hub` [Intel NUC home server](https://github.com/suderman/nixos/tree/main/systems/hub)
- `kit` [2024 FormD T1 desktop](https://github.com/suderman/nixos/tree/main/systems/kit)
- `lux` [Intel NUC media server](https://github.com/suderman/nixos/tree/main/systems/lux)  
- `sol` [Linode VPS](https://github.com/suderman/nixos/tree/main/systems/sol)
- `wit` [Thinkpad T480s laptop](https://github.com/suderman/nixos/tree/main/systems/wit)
