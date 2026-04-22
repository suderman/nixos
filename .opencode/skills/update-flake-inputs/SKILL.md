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
- If the repo already has a documented update command, use it.
- If the repo does not specify a preferred command, prefer targeted flake update commands rather than broad updates.

## Workflow

1. Identify the requested scope.
   - If the user named specific inputs, update only those.
   - Otherwise inspect `flake.nix` and `flake.lock` and choose a conservative update scope.

2. Inspect the current state.
   - Read `flake.nix` and `flake.lock`.
   - Note which inputs are top-level and which are follows/indirect.
   - Watch for repo comments that say certain inputs should stay pinned.

3. Perform the update.
   - Prefer targeted commands for named inputs.
   - Avoid broad `flake.lock` churn unless the user explicitly asked for a full refresh.
   - If an input name is ambiguous, stop and explain the ambiguity.

4. Review the diff.
   - Confirm that only the expected inputs changed.
   - Call out indirect follower changes separately.

5. Validate.
   - First run the lightest repo-appropriate validation.
   - Then run any obvious flake-level checks the repo expects.
   - If the repo has host-specific or package-specific checks tied to the changed input, run the most relevant one.

6. Report.
   - List updated inputs.
   - List any indirect changes.
   - List validation commands run and whether they passed.
   - List anything skipped because of ambiguity, policy, or failure.

## Guardrails

- Do not convert manual dependency pins into flake inputs unless the user asks for a refactor.
- Do not combine flake-input updates with unrelated cleanup.
- Do not commit, push, or create PRs unless explicitly asked.
- If a broad flake update causes surprising churn, stop and summarize instead of improvising more changes.

## Output format

Use this structure in the final report:

### Updated flake inputs
- `<input>`: `<old>` -> `<new>`

### Indirect lockfile changes
- `<input>`: `<reason>`

### Validation
- `<command>`: passed/failed

### Notes
- ambiguity, skipped items, or follow-up recommendations
