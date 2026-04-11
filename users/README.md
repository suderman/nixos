# NixOS users and identities

Each directory under `users/` is exported as `flake.users.<name>` by `lib/users.nix`.
These are **NixOS users / service identities**, not Home Manager users.

This tree is the source of truth for user-level identity material:

- NixOS user metadata from `default.nix`
- encrypted password in `password.age`
- generated SSH public key in `id_ed25519.pub`
- generated age public key in `id_age.pub`

Examples in this repo include both normal login users (`jon`, `ness`, `bot`) and
system users (`root`, `btrbk`, `beszel`).

## How it is consumed

`modules/nixos/default/configs/users.nix` is the main wiring:

- it turns host Home Manager usernames plus `root` into `config.users.users.<name>` entries using `flake.users`
- it exposes every `users/<name>/password.age` file as an agenix secret
- it hashes those passwords into `/run/user/<name>` during activation
- it installs derived SSH and age keys into each configured user's home directory

Important: entries in `users/` are not Home Manager modules. Host-specific Home
Manager imports still live under `hosts/<host>/users/...`.

Also note that some service modules use identities from `users/<name>/` even
when they manage the actual system account themselves. For example, `beszel`
and `btrbk` reuse keys from this tree.

## Defaults from `lib/users.nix`

- non-root entries default `name = <directory name>`
- `isSystemUser = false` unless set otherwise
- `isNormalUser = ! isSystemUser`
- `useDefaultShell = true`
- `linger = true` for non-root users
- `root` is special-cased with `uid = 0` and `linger = false`

## Creating a new user

Use:

```sh
nixos add user
```

That scaffolds `users/<name>/`, creates `password.age`, stages the new files in
git, and then runs `nixos generate` to refresh generated public keys and rekey
secrets.
