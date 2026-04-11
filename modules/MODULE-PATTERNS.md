# Module patterns

This repo uses [blueprint](https://numtide.github.io/blueprint/) for the top-level flake layout, then adds its own structure inside `modules/home` and `modules/nixos`.

## Flake outputs

- `modules/home/default` is exported as `flake.homeModules.default`.
- `modules/nixos/default` is exported as `flake.nixosModules.default`.
- `modules/home/desktop/*` is exported under `flake.homeModules.desktop.*`.
- `modules/nixos/desktop/*` is exported under `flake.nixosModules.desktop.*`.
- `modules/home/users/*` is exported under `flake.homeModules.users.*`.
- `modules/nixos/hardware/*` is exported under `flake.nixosModules.hardware.*`.

This mapping is defined in `lib/homeModules.nix` and `lib/nixosModules.nix`.

## The shared base: `default`

Regular machine configs import `flake.nixosModules.default` from `hosts/<name>/configuration.nix`.
The installer ISO is a special case and does not use the normal shared default module.
Every Home Manager config imports `flake.homeModules.default` from its host-specific user module.

Inside both `modules/home/default` and `modules/nixos/default`:

- `configs/` contains direct configuration modules that are always imported as-is.
- `options/` contains optional modules, usually programs and services, gated with `enable` booleans.

Both `configs/default.nix` and `options/default.nix` use `flake.lib.ls ./.;` to import the directory contents automatically.

### Placement rule

When adding a new module:

- put always-on shared policy in `default/configs/`
- put opt-in Home Manager programs in `modules/home/default/options/`
- put opt-in NixOS services/programs in `modules/nixos/default/options/`

## The desktop layer

`modules/home/desktop` and `modules/nixos/desktop` are for graphical systems only.
Keep headless/server-safe modules out of these directories.

Both sides have `desktop/default`, which:

- imports `./configs` and `./options`
- sets `desktop.enable = true`

Treat `desktop/default` as the shared graphical baseline.

Next to that are desktop-environment-specific modules such as:

- `modules/home/desktop/gnome/default.nix`
- `modules/home/desktop/hyprland/default.nix`
- `modules/nixos/desktop/hyprland.nix`

These modules carry the opinionated setup for one desktop environment, and import `flake.*Modules.desktop.default` first.

### Placement rule

- shared GUI config or GUI-only optional modules belong in `desktop/default/{configs,options}`
- opinionated desktop-environment setup belongs in a sibling like `desktop/gnome` or `desktop/hyprland`

## The repo-specific third directories

### `modules/home/users`

This is for shared Home Manager config per user identity, not per host.

Examples:

- `flake.homeModules.users.jon`
- `flake.homeModules.users.bot`
- `flake.homeModules.users.ness`

Use this when a user should get similar Home Manager behavior across multiple hosts. Host-specific overrides still live under `hosts/<host>/users/...`.

### `modules/nixos/hardware`

This is for reusable hardware modules specific to this repo. They complement upstream `nixos-hardware` rather than replacing it.

Example: `modules/nixos/hardware/framework-11th-gen-intel.nix` imports the upstream Framework module, then adds local defaults.

## How hosts are expected to compose modules

Typical host structure:

- `hosts/<host>/configuration.nix` imports `flake.nixosModules.default`
- desktop hosts also import something like `flake.nixosModules.desktop.hyprland`
- host-specific Home Manager user files import `flake.homeModules.default`
- those user files may also import `flake.homeModules.desktop.<env>` and `flake.homeModules.users.<name>`

This keeps:

- baseline shared behavior in `default`
- desktop-only behavior in `desktop`
- per-user shared behavior in `home/users`
- host-specific decisions in `hosts/<host>/...`

## Authoring guidance

- Follow the directory intent before creating new paths or abstractions.
- Prefer adding a new optional module under `options/` instead of hardcoding feature config into `configs/`.
- If a module only makes sense on graphical machines, put it under `desktop`, not under the always-on `default` tree.
- If config is shared by the same user across hosts, prefer `modules/home/users/<name>` over duplicating it per host.
- If config is tied to a hardware class, prefer `modules/nixos/hardware/<name>.nix` over embedding it directly into one host.
