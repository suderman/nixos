# Dotfiles

Jon's dotfiles and system configuration

## Commands 

```
# rebuild the whole system with nixos-rebuild
sudo echo nixos-rebuild switch --flake .#$(hostname)'

# rebuild the home directory with home-manager
home-manager switch --extra-experimental-features 'nix-command flakes' --flake '.#$(hostname)'

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
