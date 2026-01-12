# NixOS system configurations & dotfiles

![nixos](https://socialify.git.ci/suderman/nixos/image?description=1&font=Inter&logo=https%3A%2F%2Fupload.wikimedia.org%2Fwikipedia%2Fcommons%2F3%2F35%2FNix_Snowflake_Logo.svg&name=1&owner=1&pattern=Circuit%20Board&theme=Auto)

_Welcome to the NixOS configuration for my personal infrastucture!_

Among others, this flake depends on the following fantastic
[Nix](https://nixos.org/) projects:

- [blueprint](https://github.com/numtide/blueprint)
- [devshell](https://github.com/numtide/devshell)
- [agenix](https://github.com/ryantm/agenix)
- [agenix-rekey](https://github.com/oddlama/agenix-rekey)
- [impermanence](https://github.com/nix-community/impermanence)
- [disko](https://github.com/nix-community/disko)
- [home-manager](https://github.com/nix-community/home-manager)
- [stylix](https://github.com/danth/stylix)
- [nix-index-database](https://github.com/Mic92/nix-index-database)
- [nix-flatpak](https://github.com/gmodena/nix-flatpak)
- [nix-hardware](https://github.com/NixOS/nixos-hardware)
- [NUR](https://github.com/nix-community/NUR)

## Getting Started

Enter the development environment:

```sh
nix develop
```

Common commands available in the devshell:

- `nixos` - Deploy hosts and generate files
- `agenix` - Manage secrets and identity
- `browse` - Browse flake structure

Add a new host or user:

```sh
nixos add host
nixos add user
```

Generate missing files (keys, certificates):

```sh
nixos generate
```

Deploy configuration to a host:

```sh
nixos deploy
```

## Sections

- [NixOS host configurations](https://github.com/suderman/nixos/tree/main/hosts)
- [NixOS & Home Manager modules](https://github.com/suderman/nixos/tree/main/modules)
- [NixOS & Home Manager secrets](https://github.com/suderman/nixos/tree/main/secrets)
- [NixOS user configurations](https://github.com/suderman/nixos/tree/main/users)
- [Networking](https://github.com/suderman/nixos/tree/main/zones)
- [Custom packages](https://github.com/suderman/nixos/tree/main/packages)
- [Hyprland desktop configuration](https://github.com/suderman/nixos/tree/main/modules/home/desktop/hyprland)

## Resources

- [NixOS Packages](https://search.nixos.org/packages)
- [NixOS Options](https://search.nixos.org/options)
- [Home Manager Options](https://home-manager-options.extranix.com/)

When trying to figure out how to do something, examples are almost always best.
Make use of GitHub's search with the code language filter to find examples from
other Nix users' personal configurations.

For example, here is `config.services.nginx`:

<https://github.com/search?type=code&q=lang%3Anix+config.services.nginx>
