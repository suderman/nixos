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
- if no hosts are passed, use `nixos cache` interactive multi-select
- build and push hosts sequentially for deterministic logs

## Workflow

1. Confirm the target cache and host scope.
   - Default cache: `main`
   - Default host scope: interactive selection when no hosts were passed
    - Respect explicit host arguments from the user or command

2. **Build each host individually with a 60 minute timeout each.**
   - Large hosts (with Ollama, CUDA, Electron, Qt, WebKit etc.) can take 10+ minutes
     to download inputs and compile.
   - Run each host in a **separate** `nix develop --command nixos cache <host>`
     invocation so each has its own timeout context and does not block others.

3. Run the repo command.
   - Dry-run first when the user is asking what would happen
   - Real run when the user asks to build/push

4. Report clearly.
   - Which hosts were built
   - Which cache they were pushed to
   - Any host failures, with the first failing command

## Commands

Dry-run with interactive host selection:

```sh
nix develop --command nixos cache --dry-run
```

Build and push with interactive host selection:

```sh
nix develop --command nixos cache
```

Build and push specific hosts:

```sh
nix develop --command nixos cache hub kit pow
```

Build and push all hosts without prompting:

```sh
nix develop --command nixos cache --all
```

Include `iso` too:

```sh
nix develop --command nixos cache --all --include-iso
```

## Guardrails

- Do not bypass the repo `nixos cache` wrapper with ad hoc build/push commands unless the user asks.
- Do not deploy or switch hosts here; this skill is only for build-and-push.
- Do not silently include `iso` unless explicitly requested.
- Do not commit or push git changes unless the user explicitly asks.
