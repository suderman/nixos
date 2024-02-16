# NixOS system configurations & dotfiles

![nixos](https://socialify.git.ci/suderman/nixos/image?description=1&language=1&name=1&owner=1&pattern=Circuit%20Board&theme=Auto)

*Welcome to the NixOS configuration for all my personal infrastucture!*  

Feel free to look around but realize this is an on-going work-in-progress.
Although I'm a Nix enthusiast, I am *not* a Nix expert, so there's probably
always a better way to do what I'm trying to do. I have found
[Nix](https://nixos.org/) to be very challenging, but almost always in a good
way. 🤓

## Usage 

This configuration comes with a helper CLI
[nixos](https://github.com/suderman/nixos/tree/main/overlays/bin/nixos-cli) for
common commands. On a bare system, this can tool can be used by setting the
following alias:

```bash
alias nixos="bash <(curl -sL https://github.com/suderman/nixos/raw/main/overlays/bin/nixos-cli/nixos)"
```

Keep in mind this is meant to be run on NixOS and there a number of
dependencies like `jq` and `smenu` (which should automatically be installed
when needed).

### Deploy Commands

```bash
# Deploy flake to local/remote system with nixos-rebuild
nixos deploy
nixos deploy --boot
nixos deploy --test

# Rollback to the previous generation 
nixos rollback
nixos rollback --boot

# Update flake.lock to latest
nix flake update

# Install a NixOS configuration on fresh hardware or VPS
nixos bootstrap
```

See [bootstrap configuration](https://github.com/suderman/nixos/tree/main/configurations/bootstrap) for more details.

### Secrets Commands

```bash
# Edit or add secrets to secrets/files/* (wrapper for agenix --edit)
nixos secrets

# Rekey existing secrets with secrets/keys/* (wrapper for agenix --rekey)
nixos rekey

# Scan a host for public keys and add to secrets/keys/* (wrapper for ssh-keyscan)
nixos keyscan IP [HOSTNAME]
```

See [secrets](https://github.com/suderman/nixos/tree/main/secrets) for more details.

### Utility Commands

```bash
# Start a repl to browse this flake
nixos repl
```

The above is a wrapper for `nix repl` using [repl.nix](https://github.com/suderman/nixos/blob/main/repl.nix) to load everything. 

## Resources

- [NixOS Packages](https://search.nixos.org/packages)
- [NixOS Options](https://search.nixos.org/options)
- [Home Manager Options](https://mipmip.github.io/home-manager-option-search)

When trying to figure out how to do something, examples are almost always best.
Make use of GitHub's search with the code language filter to find examples from
other Nix users' personal configurations. 

For example, here is `config.services.nginx`:

<https://github.com/search?type=code&q=lang%3Anix+config.services.nginx>

