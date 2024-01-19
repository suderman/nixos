# NixOS configurations

The `all` directory contains shared configuration automatically
imported in every system below. Shared NixOS configuration files are found in
`configurations/all/configuration.nix` and shared Home Manager configuration
files are found in  `configurations/all/users/all/home.nix`. Also, user-specific
Home Manager configurations for all systems can be found in 
`configurations/all/users/*.nix` or `configurations/all/users/*/home.nix`

- `all` [Shared configuration](https://github.com/suderman/nixos/tree/main/configurations/all)

Each of these directories are automatically imported and available in my
flake's `outputs.nixosConfigurations.*`. NixOS configuration files can be found in
`configurations/*/configuration.nix` and Home Manager configurations can be found in 
`configurations/*/users/*.nix` or `configurations/*/users/*/home.nix`

- `bootstrap` [Bootstrap configuration](https://github.com/suderman/nixos/tree/main/configurations/bootstrap)
- `cog` [Framework laptop](https://github.com/suderman/nixos/tree/main/configurations/cog)
- `eve` [2009 Mac Pro (at work)](https://github.com/suderman/nixos/tree/main/configurations/eve)
- `hub` [Intel NUC home server](https://github.com/suderman/nixos/tree/main/configurations/hub)  
- `lux` [Intel NUC media server](https://github.com/suderman/nixos/tree/main/configurations/lux)  
- `rig` [2009 Mac Pro (at home)](https://github.com/suderman/nixos/tree/main/configurations/rig) 
- `sol` [Linode VPS](https://github.com/suderman/nixos/tree/main/configurations/sol)
- `wit` [Thinkpad T480s laptop](https://github.com/suderman/nixos/tree/main/configurations/wit)
