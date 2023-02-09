# secrets

Sensitive [files](https://github.com/suderman/nixos/tree/main/secrets/files)
are age-encrypted using the [agenix](https://github.com/ryantm/agenix) CLI,
and decrypted by that module using SSH public
[keys](https://github.com/suderman/nixos/tree/main/secrets/keys). The
[secrets.nix](https://github.com/suderman/nixos/blob/main/secrets/secrets.nix)
file is not imported into my NixOS configuration, but strictly used by the `agenix` CLI.

## Module Usage

By default, secrets are not enabled for a host configuration. This is to avoid 
problems installing this repo onto a new system that hasn't yet been authenticated 
(had their host key added). To have access to these secrets, the host configuration 
should include the following:

```nix
{ config, ... }: {

    # Enable secrets
    secrets.enable = true;
}
```

Inside a module, a helpful usage pattern is to combine `secrets.files` and 
`secrets.enable` attributes with `age` in the `let` block:

```nix
{ config, pkgs, lib, ... }:
  
let 

  # agenix secrets combined with age files paths
  age = config.age // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };
  
in {
  # ...
```

Then, in the config section of this module, set the `age.secrets` attribute as
described in the [agenix
documentation](https://github.com/ryantm/agenix#reference), but as an
condition of secrets being enabled and also using the path to the encrypted file
given above:

```nix
{ #...

  # agenix
  age.secrets = lib.mkIf age.enable {
    example-env.file = age.files.example-env;
  };

  # service
  virtualisation.oci-containers.containers."example" = {
    environmentFiles = lib.mkIf age.enable [ age.secrets.example-env.path ];
    # ...
  };

}
```

## CLI Commands

A few helper
[scripts](https://github.com/suderman/nixos/tree/main/secrets/scripts) are
included to streamline the management of secrets, which is a bit of a manual
process when using the `agenix` CLI alone:

#### `secrets-keyscan HOST [NAME]`

This script is a wrapper around `ssh-keyscan` which discovers SSH host public
keys. When invoked, the host (or IP address) is asked to return an
`ssh-ed25519` public key, which gets saved as `NAME.pub` in the `keys`
directory. Then, the `secrets-rekey` script is run, which is explained next. 

#### `secrets-rekey [--force]`

This script is wrapper around `agenix --rekey`. First, the `keys/default.nix`
file gets regenerated to include all keys found in that directory. If any
changes are detected (or the `--force` flag is used), `agenix --rekey` is run,
which re-encrypts all `age` files with the rules found in `secrets.nix` and
keys available. Lastly, the `secrets` folder is staged on `git`.

#### `secrets [NAME]`

This script is wrapper around `agenix --edit`. First, a list of existing
secrets (found in `secrets.nix`) is presented, unless a secret's `name` is
provided as an argument. If the desired secret doesn't yet exist, it is added
to the `secrets.nix` file. Next, `agenix --edit` is run, opening an editor for
the secret. After saving any changes, the `files/default.nix` file gets
regenerated in case there is a new `age` file to include in the list. Lastly,
the `secrets` folder is staged on `git`.

## CLI Usage

To add a system key from a host named `foo`, first get that host's IP address
and run the following command:

    secrets-keyscan 123.123.123.123 foo

To add a user key named `bar`, manually add the user's public key as `@bar.pub`
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
