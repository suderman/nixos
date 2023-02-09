# secrets

Sensitive [files](https://github.com/suderman/nixos/tree/main/secrets/files)
are age-encrypted using the [agenix](https://github.com/ryantm/agenix) CLI,
and decrypted by that module using SSH public
[keys](https://github.com/suderman/nixos/tree/main/secrets/keys). The
[secrets.nix](https://github.com/suderman/nixos/blob/main/secrets/secrets.nix)
file is not imported into my NixOS configuration, but strictly used by the `agenix` CLI.

By default, secrets are not enabled for a host configuration. This is to avoid 
problems installing this repo onto a new system that hasn't yet been authenticated 
(had their host key added). To have access to these secrets, the host configuration 
should include the following:

    { config, ... }: {
    
        # Enable secrets
        secrets.enable = true;
    }

## Commands

A few helper
[scripts](https://github.com/suderman/nixos/tree/main/secrets/scripts) are
included to streamline the management of secrets, which is a bit of a manual
process when using the `agenix` CLI alone:

### `secrets-keyscan HOST [NAME]`

This script is a wrapper around `ssh-keyscan` which discovers SSH host public
keys. When invoked, the host (or IP address) is asked to return an
`ssh-ed25519` public key, which gets saved as `NAME.pub` in the `keys`
directory. Lastly, the `secrets-rekey` script is run, which is explained next. 

### `secrets-rekey [--force]`

This script is wrapper around `agenix --rekey`. First, the `keys/default.nix`
file gets regenerated to include all keys found in that directory. If any
changes are detected (or the `--force` flag is used), `agenix --rekey` is run,
which re-encrypts all `age` files with the rules found in `secrets.nix` and
keys available. Lastly, the `secrets` folder is staged on `git`.

### `secrets [NAME]`

This script is wrapper around `agenix --edit`. First, a list of existing
secrets (found in `secrets.nix`) is presented, unless a secret's `name` is
provided as an argument. If the desired secret doesn't yet exist, it is added
to the `secrets.nix` file. Next, `agenix --edit` is run, opening an editor for
the secret. After saving any changes, the `files/default.nix` file gets
regenerated in case there is a new `age` file to include in the list. Lastly,
the `secrets` folder is staged on `git`.

## Usage

To add a system key from a host named `foo`, first get that host's IP address
and run the following command:

    secrets-keyscan 123.123.123.123 foo

To add a user key named `bar`, manually add the user's public key as `bar.pub`
to the `secrets/keys` directory. Then run the following command:

    secrets-rekey

To change an existing secret, run the following command and choose the secret:

    secrets

To add a new secret named `foobar`, run the following command:

    secrets foobar

To remove a key, manually remove that `pub` file from the `secrets/keys`
directory. Also remove any reference to that key in the `secrets/secrets.nix`
file. Then run the follwing command:

    secrets-rekey

To remove a secret, manually remove that `age` file from the `secrets/files`
directory. Next, remove any references to that file in the
`secrets/secrets.nix` file. Also, remove any references to this secret in the
[modules](https://github.com/suderman/nixos/tree/main/modules) directory. Then
run the following command:

    secrets-rekey