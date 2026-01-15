# Agent Instructions for NixOS Configuration

This repository contains NixOS system configurations managed as a Flake, using `blueprint` for structure and `devshell` for development tooling.

## 1. Environment & Workflow

### Development Shell
Always operate within `nix develop`.
- **Enter:** `nix develop`
- **Tools:** `nixos`, `agenix`, `alejandra` are available.

### Core Commands
Use the custom `nixos` wrapper script for most operations.

- **Deploy:** `nixos deploy` (Interactive `nixos-rebuild` wrapper)
- **Add Resource:**
  - `nixos add host` - scaffolds `hosts/<name>`
  - `nixos add user` - scaffolds `users/<name>`
- **Generate:** `nixos generate` (SSH keys, age identities, rekeys secrets)
  - May prompt for password if `/tmp/id_age` is missing (runs `agenix unlock`)
- **Simulation:**
  - `nixos sim up` - Start QEMU VM
  - `nixos sim rebuild` - Rebuild running VM
  - `nixos sim ssh` - SSH into VM

### Build & Test
- **Check:** `nix flake check`
- **Build:** `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- **ISO:** `nixos iso build`
- **Format:** `alejandra .`

## 2. Code Style & Structure

### File Structure (Blueprint)
This repo follows the `numtide/blueprint` convention:
- `hosts/`: Per-machine configurations.
- `modules/`: Reusable NixOS/Home Manager modules.
  - `nixos/`: System-level modules.
  - `home/`: User-level (home-manager) modules.
- `users/`: Potential system users (`config.users.users.<name>`). Not all are available on all hosts; availability determined by host's `home-manager.users` and module includes.
- `packages/`: Custom packages.
- `secrets/`: Encrypted secrets (Agenix).
- `zones/`: Networking/DNS configurations.

### Module Organization
- `default/`: Imported in every host/home.
- `desktop/`: Imported in any graphical environment.
- `hardware/` (nixos only): Custom hardware modules for specific hosts.
- `users/` (home only): Per-user home configs shared across hosts.

### Optional vs Non-Optional Configs
Inside `default/` and `desktop/` subfolders:
- `configs/`: Non-optional configuration applied as-is.
- `options/`: Optional configuration; each file requires `enable = true`.

### Nix Style
- **Formatter:** Strict adherence to `alejandra`. Run `nix fmt` after changes.
- **Patterns:** Prefer pure functions. Use `lib.mkIf`, `lib.mkMerge`.
- **Imports:** Use relative paths for local imports.
- **Comments:** Comment complex logic, especially for hardware quirks.

### Secrets (Agenix)
- **Never** commit plain text secrets.
- **Storage:** `secrets/` or within `users/`/`hosts/` as `.age` files.
- **Edit:** `agenix -e <path/to/secret.age>`
- **Rekey:** `agenix rekey` (handled by `nixos generate`).

## 3. Creating New Configurations

### New Host
1. Run `nixos add host`.
2. Edit `hosts/<name>/configuration.nix`.
3. Configure `hardware-configuration.nix` (`nixos detect hardware`).
4. Configure `disk-configuration.nix` (Disko).

### New User
1. Run `nixos add user`.
2. Edit `users/<name>/default.nix`.
3. Add to host's `home-manager.users` and/or system users.

## 4. Verification Checklist
Before submitting changes:
1. [ ] Run `nix fmt`
2. [ ] Run `nix flake check`
3. [ ] If adding a package: `nix build .#<package-name>`
4. [ ] If modifying a host: `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.outPath`

## 5. Tools Reference
- **Nix:** `nix repl`, `nix inspect` (via `browse` command)
- **Shell:** `gum` for interactivity
- **Version Control:** Standard `git`
