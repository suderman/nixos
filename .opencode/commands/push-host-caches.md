---
description: Build NixOS host closures and push them to Attic
subtask: true
---

You are preparing Attic cache entries for this repository's NixOS hosts.

Requested hosts: `$ARGUMENTS`

Follow this workflow:

1. Read `AGENTS.md` if present.
2. Read `.opencode/skills/build-push-hosts/SKILL.md` and follow it exactly.
3. Use the deterministic `nixos cache` subcommand.
4. Work from `nix develop`.
5. If no hosts were provided, push all normal hosts and exclude `iso` by default.
6. Report:
   - cache name used
   - hosts processed
   - whether it was a dry-run or a real push
   - any failures

If the user asks for a preview first, run:

```sh
nix develop --command nixos cache dry-run $ARGUMENTS
```

Otherwise run:

```sh
nix develop --command nixos cache push $ARGUMENTS
```
