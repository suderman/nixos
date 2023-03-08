# NixOS system configurations

![nixos](https://socialify.git.ci/suderman/nixos/image?description=1&language=1&name=1&owner=1&pattern=Circuit%20Board&theme=Dark)

## Commands 

```
# rebuild the whole system with nixos-rebuild
sudo nixos-rebuild switch

# update
nix flake update
```

## Browse config

```
nix repl
:lf .
outputs.nixosConfigurations.<tab>
outputs.homeConfigurations.<tab>
inputs.<tab>
```
