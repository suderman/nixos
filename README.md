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

## Note

This is a work-in-progress as I migrate from
[legacy branch](https://github.com/suderman/nixos/tree/legacy).

## Sections

- [NixOS host configurations](https://github.com/suderman/nixos/tree/main/hosts)
- [NixOS & Home Manager modules](https://github.com/suderman/nixos/tree/main/modules)
- [NixOS & Home Manager secrets](https://github.com/suderman/nixos/tree/main/secrets)
- [NixOS user configurations](https://github.com/suderman/nixos/tree/main/users)
- [Networking](https://github.com/suderman/nixos/tree/main/zones)
- [Hyprland desktop configuration](https://github.com/suderman/nixos/tree/main/modules/home/desktops/hyprland)

## Resources

- [NixOS Packages](https://search.nixos.org/packages)
- [NixOS Options](https://search.nixos.org/options)
- [Home Manager Options](https://home-manager-options.extranix.com/)

When trying to figure out how to do something, examples are almost always best.
Make use of GitHub's search with the code language filter to find examples from
other Nix users' personal configurations.

For example, here is `config.services.nginx`:

<https://github.com/search?type=code&q=lang%3Anix+config.services.nginx>
