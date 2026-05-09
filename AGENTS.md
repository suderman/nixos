# /etc/nixos agent notes

- Work from `nix develop`. Repo-specific tools (`nixos`, `agenix`, `derive`, `sshed`, `browse`, `alejandra`) come from the devshell.
- `nixos` and `agenix` here are wrapper scripts from `packages/`, not stock CLIs. Many subcommands are interactive (`gum`) and some auto-stage files in git; avoid them for unattended automation unless you want that behavior.

## Read before changing repo structure

- Module placement and import conventions: `modules/MODULE-PATTERNS.md`
- Networking, DNS, CA, Traefik, and Tailscale model: `modules/NETWORKING-PATTERNS.md`
- `users/` is NixOS users/service identities, not Home Manager users: `users/README.md`
- Deterministic secret/key recovery and agenix workflow: `secrets/README.md`

## High-impact commands

- Format: `nix fmt` (or `alejandra .` inside the devshell).
- Eval one host without building: `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.outPath`
- Build one host: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Full repo check: `nix flake check`
- Build installer ISO: `nix build .#nixosConfigurations.iso.config.system.build.isoImage`
- Non-interactive deploy equivalent: `nixos-rebuild --flake .#<host> [switch|boot|test|build|repl]`

## Generated / secret-backed workflows

- `nixos generate` is broad: it unlocks `secrets/id_age.age` into `/tmp/id_age`, rewrites host/user public keys under `hosts/*` and `users/*`, ensures `zones/ca.{crt,age}` exists, and runs `agenix rekey -a`.
- `nixos add host|user` scaffolds files, stages them in git, then runs `nixos generate`.
- Edit secrets with `agenix edit <path>.age`. After changing recipients or adding/removing secrets, run `agenix rekey -a` (or `nixos generate`). Never commit plaintext secrets.

## Repo structure that matters

- This flake uses `blueprint`: directories map directly to flake outputs.
- `hosts/<name>/configuration.nix` defines `nixosConfigurations.<name>`.
- Shared system modules live in `modules/nixos/`; shared Home Manager modules live in `modules/home/`.
- Per-host Home Manager configs live in either `hosts/<host>/users/<user>.nix` or `hosts/<host>/users/<user>/home-configuration.nix`.
- `users/<name>/` holds NixOS user/service identity data plus generated public keys and encrypted passwords.
- `zones/*/default.nix` is the source of truth for IP data; the zone READMEs are router/admin runbooks.

## Repo-specific module conventions

- `modules/nixos/default/default.nix` imports `./configs`, `./options`, and `./overlays`; `modules/home/default/default.nix` imports `./configs` and `./options`.
- Before inventing new helpers, check `modules/README.md`: this repo already extends modules with `persist`, `tmpfiles`, extra `networking.*`, and Home Manager `home.uid` / `home.portOffset`.
- New opt-in programs/services usually belong in `modules/{home,nixos}/default/options/`; desktop-only modules belong under `modules/{home,nixos}/desktop/`.

## Hyprland Lua migration status

- Hyprland 0.55 migration is in progress. Only `kit` currently enables the Lua path via `wayland.windowManager.hyprland.lua.enable`.
- `pow` and `cog` still rely on Home Manager-generated hyprlang, so many modules intentionally keep duplicate `wayland.windowManager.hyprland.settings` definitions as compatibility shadow config.
- Preferred new pattern for feature-local Hyprland behavior is:
  - put the feature in its owning module
  - add Lua with `wayland.windowManager.hyprland.lua.features.<name> = '' ... '';`
  - avoid standalone `.lua` files unless the module already spans a directory for other reasons
- Core shared Lua lives under `modules/home/desktop/hyprland/lua/`. Keep that for compositor-wide behavior only, not app-specific binds/rules.

### Before removing generated hyprlang entirely

1. Enable the Lua path on all Hyprland hosts, not just `kit`.
2. Runtime-test those hosts in real sessions, not just `nix eval`.
3. Remove shadow `wayland.windowManager.hyprland.settings` definitions after their Lua equivalents are verified.
4. Delete old Home Manager hyprlang-generation paths only after all hosts boot cleanly on Lua.

### Known later-migration checklist

These still contain `wayland.windowManager.hyprland.settings` and should be reviewed before deleting hyprlang generation:

- Core Hyprland modules:
  - `modules/home/desktop/hyprland/hypr/main.nix`
  - `modules/home/desktop/hyprland/hypr/graphics.nix`
  - `modules/home/desktop/hyprland/hypr/layouts.nix`
  - `modules/home/desktop/hyprland/hypr/workspaces.nix`
  - `modules/home/desktop/hyprland/hypr/windows.nix`
  - `modules/home/desktop/hyprland/hypr/groups.nix`
  - `modules/home/desktop/hyprland/hypr/floating.nix`
  - `modules/home/desktop/hyprland/hypr/fullscreen.nix`
  - `modules/home/desktop/hyprland/hypr/launchers.nix`
  - `modules/home/desktop/hyprland/hypr/special.nix`
  - `modules/home/desktop/hyprland/hypr/supertab.nix`
- Hyprland feature modules with Lua shadow already in place:
  - `modules/home/desktop/hyprland/printscreen.nix`
  - `modules/home/desktop/hyprland/mediactl.nix`
  - `modules/home/desktop/hyprland/mako.nix`
  - `modules/home/desktop/hyprland/swww.nix`
  - `modules/home/desktop/hyprland/waybar/default.nix`
  - `modules/home/desktop/hyprland/waybar/modules-center.nix`
  - `modules/home/desktop/hyprland/wlogout.nix`
  - `modules/home/desktop/hyprland/hypridle.nix`
  - `modules/home/desktop/hyprland/rofi/default.nix`
  - `modules/home/desktop/hyprland/rofi/launcher.nix`
  - `modules/home/desktop/hyprland/rofi/blezz.nix`
  - `modules/home/desktop/hyprland/rofi/calc.nix`
  - `modules/home/desktop/hyprland/rofi/clips.nix`
  - `modules/home/desktop/hyprland/rofi/sinks.nix`
- Desktop option modules now carrying Lua shadows too:
  - `modules/home/desktop/default/options/chromium/default.nix`
  - `modules/home/desktop/default/options/firefox/default.nix`
  - `modules/home/desktop/default/options/freetube.nix`
  - `modules/home/desktop/default/options/gimp.nix`
  - `modules/home/desktop/default/options/imv.nix`
  - `modules/home/desktop/default/options/mpv.nix`
  - `modules/home/desktop/default/options/neomutt.nix`
  - `modules/home/desktop/default/options/obsidian.nix`
  - `modules/home/desktop/default/options/onepassword.nix`
  - `modules/home/desktop/default/options/sparrow.nix`
  - `modules/home/desktop/default/options/steam.nix`
  - `modules/home/desktop/default/options/telegram.nix`
  - `modules/home/desktop/default/options/zathura.nix`
  - `modules/home/desktop/default/options/zwift.nix`
- Low-priority cleanup: these currently expose empty Hyprland settings and can likely just lose them when hyprlang support is removed:
  - `modules/home/desktop/default/options/slack.nix`
  - `modules/home/desktop/default/options/bluebubbles.nix`

## Simulation / installer work

- `nixos sim up|rebuild|ssh` is the VM workflow for installer/disko experiments. It creates `hosts/sim/disk{1..4}.img` and derives `hosts/sim/ssh_host_ed25519_key` locally.
