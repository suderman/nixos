# NixOS configuration

Personal infrastructure configuration. Prefer lean hosts, cohesive modules, and the repository's own helpers over equivalent generic alternatives.

Before substantive work, read [docs/conventions.org](docs/conventions.org) in full. It owns standing rules for module placement, authoring, and verification. Read linked technical docs when relevant, not every runbook for every task.

For networking, DNS, Traefik, certificates, or Tailscale changes, also read [docs/networking.org](docs/networking.org).

## Working rules

- Work from `nix develop`.
- Track active tasks, progress, and follow-ups in `~/org/work/suderman/nixos/nixos.org`, not repository instructions or local plans. Keep these instructions stable.
- Verify changes proportionally. Prefer temporary probes over new permanent tests for configuration work. See the conventions before adding retained tests.
- Preserve unrelated changes. Do not move modules or remove existing tests as incidental cleanup.

## Safety

- `nixos` and `agenix` are repo wrappers. Some commands are interactive, auto-stage files, or mutate identities. Read relevant docs before using them.
- Do not run `nixos generate`, rekey secrets, or bypass identity-rotation guards as routine validation. Never commit plaintext secrets.
- Do not deploy, activate, commit, or push unless requested. Passwordless `nixos-rebuild` is capability, not permission.
