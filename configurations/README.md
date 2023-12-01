# NixOS configurations

Each of these directories are automatically imported and available in my
flake's `outputs.nixosConfigurations.*`. 

The `bootstrap` directory also contains shared configuration automatically
imported in every system below. Shared NixOS configuration files are found in
`configurations/bootstrap/nixos/*.nix` and shared Home Manager configuration
files are found in  `configurations/bootstrap/home/*.nix`.

- `bootstrap` [Bootstrap configuration](https://github.com/suderman/nixos/tree/main/configurations/bootstrap)
- `cog` [Framework laptop](https://github.com/suderman/nixos/tree/main/configurations/cog)
- `eve` [2009 Mac Pro (at work)](https://github.com/suderman/nixos/tree/main/configurations/eve)
- `hub` [Intel NUC home server](https://github.com/suderman/nixos/tree/main/configurations/hub)  
- `lux` [Intel NUC media server](https://github.com/suderman/nixos/tree/main/configurations/lux)  
- `pom` [Mac Mini](https://github.com/suderman/nixos/tree/main/configurations/pom)  
- `rig` [2009 Mac Pro (at home)](https://github.com/suderman/nixos/tree/main/configurations/rig) 
- `sol` [Linode VPS](https://github.com/suderman/nixos/tree/main/configurations/sol)
- `wit` [Thinkpad T480s laptop](https://github.com/suderman/nixos/tree/main/configurations/wit)
