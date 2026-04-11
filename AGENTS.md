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

## Simulation / installer work

- `nixos sim up|rebuild|ssh` is the VM workflow for installer/disko experiments. It creates `hosts/sim/disk{1..4}.img` and derives `hosts/sim/ssh_host_ed25519_key` locally.
