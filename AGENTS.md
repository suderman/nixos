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

- Hyprland 0.55 migration is complete for current Hyprland hosts. `kit`, `pow`, and `cog` all use `wayland.windowManager.hyprland.lua.enable`.
- Preferred new pattern for feature-local Hyprland behavior is:
  - put the feature in its owning module
  - add Lua with `wayland.windowManager.hyprland.lua.features.<name> = '' ... '';`
  - avoid standalone `.lua` files unless the module already spans a directory for other reasons
- Core shared Lua lives under `modules/home/desktop/hyprland/lua/`. Keep that for compositor-wide behavior only, not app-specific binds/rules.

### Current cleanup state

1. Legacy Home Manager-generated Hyprland config has been removed from `modules/home/desktop/**`.
2. Shared compositor behavior now lives in `modules/home/desktop/hyprland/lua/`.
3. Feature-local rules/binds/extensions should live inline in their owning module via `wayland.windowManager.hyprland.lua.features.<name>`.
4. `~/.config/hypr/local/init.lua` remains the supported writable scratch hook for quick experiments.

### Known later follow-up checklist

These no longer block Lua migration, but still deserve later review or runtime validation:

- Shared Lua core to runtime-test carefully:
  - `modules/home/desktop/hyprland/lua/hyprland.lua`
  - `modules/home/desktop/hyprland/lua/conf/session.lua`
  - `modules/home/desktop/hyprland/lua/conf/look.lua`
  - `modules/home/desktop/hyprland/lua/conf/input.lua`
  - `modules/home/desktop/hyprland/lua/conf/layouts.lua`
  - `modules/home/desktop/hyprland/lua/conf/group.lua`
  - `modules/home/desktop/hyprland/lua/binds/main.lua`
  - `modules/home/desktop/hyprland/lua/rules/windows.lua`
- Feature-local Lua snippets now embedded in:
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
  - `modules/home/desktop/hyprland/hypr/scripts/*.sh` now use Lua-aware `hyprctl dispatch`/`eval` syntax and should be smoke-tested on real sessions.
- Desktop option modules carrying app-specific Lua rules:
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
- Dynamic cursor plugin note:
  - `enablePlugins = false` is currently set on `kit`, `pow`, and `cog` because `hypr-dynamic-cursors` crashes on the Lua path. Revisit only after upstream plugin fixes.

## Simulation / installer work

- `nixos sim up|rebuild|ssh` is the VM workflow for installer/disko experiments. It creates `hosts/sim/disk{1..4}.img` and derives `hosts/sim/ssh_host_ed25519_key` locally.
