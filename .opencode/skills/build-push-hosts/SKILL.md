---
name: build-push-hosts
description: Build NixOS host closures deterministically and push them to Attic.
compatibility: opencode
metadata:
  audience: maintainers
  repo: nixos
  workflow: deploy-cache
---

## What I do

I build one or more `nixosConfigurations.<host>.config.system.build.toplevel`
closures and push them into the configured Attic cache.

I use the repo's deterministic `nixos cache` subcommand.

## When to use me

Use me when the user wants to:

- prebuild host system closures on a stronger machine
- populate the Attic cache before host-local deploys
- push all normal hosts, or a named subset, into Attic

## Default behavior

- work from `nix develop`
- push to Attic cache `main`
- include all `nixosConfigurations` except `iso`
- build and push hosts sequentially for deterministic logs

## Workflow

1. Confirm the target cache and host scope.
   - Default cache: `main`
   - Default hosts: all `nixosConfigurations` except `iso`
   - Respect explicit host arguments from the user or command

2. Run the repo command.
   - Dry-run first when the user is asking what would happen
   - Real run when the user asks to build/push

3. Report clearly.
   - Which hosts were built
   - Which cache they were pushed to
   - Any host failures, with the first failing command

## Commands

Dry-run all normal hosts:

```sh
nix develop --command nixos cache dry-run
```

Build and push all normal hosts:

```sh
nix develop --command nixos cache push
```

Build and push specific hosts:

```sh
nix develop --command nixos cache push hub kit pow
```

Include `iso` too:

```sh
nix develop --command nixos cache push --include-iso
```

## Guardrails

- Do not use the interactive `nixos` wrapper for this workflow.
- Do not deploy or switch hosts here; this skill is only for build-and-push.
- Do not silently include `iso` unless explicitly requested.
- Do not commit or push git changes unless the user explicitly asks.
