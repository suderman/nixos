# NixOS system configurations

The `all` directory contains shared configuration automatically imported in every system below. 

- `all` [Shared system configuration](https://github.com/suderman/nixos/tree/main/configurations/systems/all)

Each of these directories are automatically imported and available in my
flake's `outputs.nixosConfigurations.*`. NixOS configuration files can be found
in `configurations/systems/*/configuration.nix` and system-specific Home
Manager configurations can be found in `configurations/systems/*/users/*.nix`
or `configurations/systems/*/users/*/home.nix`

- `bootstrap` [Bootstrap configuration](https://github.com/suderman/nixos/tree/main/configurations/systems/bootstrap)
- `cog` [Framework laptop](https://github.com/suderman/nixos/tree/main/configurations/systems/cog)
- `eve` [2009 Mac Pro (at work)](https://github.com/suderman/nixos/tree/main/configurations/systems/eve)
- `fit` [2009 Mac Pro (at home)](https://github.com/suderman/nixos/tree/main/configurations/systems/fit) 
- `hub` [Intel NUC home server](https://github.com/suderman/nixos/tree/main/configurations/systems/hub)
- `kit` [2024 FormD T1 desktop](https://github.com/suderman/nixos/tree/main/configurations/systems/kit)
- `lux` [Intel NUC media server](https://github.com/suderman/nixos/tree/main/configurations/systems/lux)  
- `sol` [Linode VPS](https://github.com/suderman/nixos/tree/main/configurations/systems/sol)
- `wit` [Thinkpad T480s laptop](https://github.com/suderman/nixos/tree/main/configurations/systems/wit)
