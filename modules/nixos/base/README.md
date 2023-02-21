# Base configuration for NixOS hosts

Common defaults I like to use for each host:

## Network

- Enable firewall 
- Set host & domain names
- Disable IPv6

## Nix

- Enable experimental features and flakes support
- Automatic garbage collection 
- Automatic system upgrades

## Packages

- Basic tooling I always want available (git, curl, vim, etc)
- zsh and bash completions

## Sudo

- Password settings for sudo users

## Users

- Immutable users
- root, user and test accounts
- Use password from secrets
- Set ssh public key
