---
name: update-flake-inputs
description: Update flake inputs in a Nix flake repo with minimal churn, validate the result, and report exactly what changed.
compatibility: opencode
metadata:
  audience: maintainers
  repo: nixos
  workflow: dependency-updates
---

## What I do

I update normal flake inputs that are managed through `flake.nix` and `flake.lock`.

I am for inputs that should be updated through the flake tooling itself, not for manual version pins inside Nix modules, package derivations, container tags, Firefox addon XPI URLs, or custom fetchers outside the flake input graph.

## When to use me

Use me when the user wants to:

- update one or more flake inputs
- refresh `flake.lock`
- selectively bump specific inputs with minimal unrelated churn
- validate that the repo still evaluates or builds after the update

Do not use me for manual dependency pins handled outside `flake.lock`. Use `update-dependencies` for those.

## Working style

- Prefer targeted updates over blanket updates unless the user explicitly asks for everything.
- Never hand-edit `flake.lock`.
- Minimize churn in unrelated inputs.
- Read `AGENTS.md` and any repo-local docs that define the preferred validation flow.
- Work from `nix develop` so repo wrappers and formatter are available.
- In this repo, avoid the interactive `nixos` and `agenix` wrappers for unattended automation unless their side effects are explicitly wanted.
- If the repo does not specify a preferred command, prefer targeted flake update commands rather than broad updates.
- Use `.opencode/scripts/update-versions/pick-flake-validation.py` to choose the cheapest relevant validation host unless you have stronger repo evidence for a different host.

## Repo-specific context for this flake

- This repo uses `blueprint`, so top-level directories map directly to flake outputs.
- `hosts/<name>/configuration.nix` defines `nixosConfigurations.<name>`.
- Shared system modules live under `modules/nixos/`; shared Home Manager modules live under `modules/home/`.
- `modules/nixos/default/default.nix` imports `configs`, `options`, and `overlays`; the matching Home Manager default imports `configs` and `options`.
- Desktop-only configuration lives under `modules/{home,nixos}/desktop/`; avoid assuming those modules apply to headless hosts.
- `hosts/sim` is the VM/test host used for simulation and installer work. It is a useful targeted validation host when update fallout hits virtualization or installer-related options.
- This flake intentionally filters builder helpers like `enableWayland`, `mkScript`, `mkApplication`, and `wrapWithFlags` out of exported `packages` and `checks`; do not treat their absence from flake outputs as an update regression.
- Deterministic helper scripts live in `.opencode/scripts/update-versions/`:
  - `pick-flake-validation.py` chooses a validation host from changed inputs and paths
  - `scan-manual-pins.py` is for manual pin discovery, not normal flake-input updates

## Validation levels

Use two levels of validation and choose deliberately:

### Quick validation (default)

Use this unless the user explicitly asks for a full build-heavy validation.

- `nix develop -c nix eval .#nixosConfigurations.<relevant-host>.config.system.build.toplevel.outPath`
- `nix develop -c nix flake check --no-build`

Why:

- catches removed or renamed options and broken flake output wiring
- verifies all exported outputs still evaluate
- avoids the time, bandwidth, and disk cost of building every checked derivation in this multi-host flake

Pick the most relevant host for the changed inputs when possible:

- default fallback: `hub`
- virtualization / installer fallout: `sim`
- desktop stack fallout: a desktop host such as `cog`, `eve`, `kit`, `lux`, `pow`, or `wit`, whichever is most relevant
- ISO / installer-specific inputs: `iso`

### Full validation (heavy, optional)

Only run this when the user asks for stronger assurance, or when quick validation reveals an issue that requires realization/build confirmation.

- `nix develop -c nix build .#nixosConfigurations.<relevant-host>.config.system.build.toplevel`
- `nix develop -c nix flake check`

Warn in the report when full validation was skipped because it may require substantial time, network, and store space in this repo.

## Workflow

1. Identify the requested scope.
   - If the user named specific inputs, update only those.
   - Otherwise inspect `flake.nix` and `flake.lock` and choose a conservative update scope.

2. Inspect the current state.
    - Read `flake.nix` and `flake.lock`.
    - Note which inputs are top-level and which are follows/indirect.
    - Watch for repo comments that say certain inputs should stay pinned.
    - Note which hosts or module areas are most likely to be affected by the specific input change.

3. Perform the update.
     - Prefer targeted commands for named inputs.
     - Avoid broad `flake.lock` churn unless the user explicitly asked for a full refresh.
     - If an input name is ambiguous, stop and explain the ambiguity.
     - Prefer `nix develop -c nix flake lock --update-input <name>` for targeted updates.
     - Use `nix develop -c nix flake update` only when the user asked for a broad refresh.
     - When the user asked for "all" flake inputs, still review `flake.nix` first so you can call out intentionally pinned inputs like `hyprland` and `hypr-dynamic-cursors` separately from floating inputs.

4. Review the diff.
    - Confirm that only the expected inputs changed.
    - Call out indirect follower changes separately.
    - Distinguish direct top-level input bumps from lockfile churn caused by follows.

5. Validate.
     - Run quick validation by default.
     - Use a relevant host eval in addition to `nix flake check --no-build`.
     - Prefer to choose that host by running `python3 .opencode/scripts/update-versions/pick-flake-validation.py --input <name> ...` and using the returned quick/full commands.
     - Escalate to full validation only when explicitly requested or clearly warranted.
     - If full validation is skipped, say so explicitly and explain that it is the heavy path in this multi-host flake.

6. Report.
    - List updated inputs.
    - List any indirect changes.
    - List validation commands run, whether they passed, and whether they were quick or full.
    - List anything skipped because of ambiguity, policy, or failure.

## Guardrails

- Do not convert manual dependency pins into flake inputs unless the user asks for a refactor.
- Do not combine flake-input updates with unrelated cleanup.
- Do not commit, push, or create PRs unless explicitly asked.
- If a broad flake update causes surprising churn, stop and summarize instead of improvising more changes.
- Do not silently run full `nix flake check` as the default validation path in this repo.

## Output format

Use this structure in the final report:

### Updated flake inputs
- `<input>`: `<old>` -> `<new>`

### Indirect lockfile changes
- `<input>`: `<reason>`

### Validation
- Quick:
  - `<command>`: passed/failed
- Full:
  - `<command>`: passed/failed/skipped

### Notes
- ambiguity, skipped items, or follow-up recommendations
