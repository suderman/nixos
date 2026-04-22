---
name: update-dependencies
description: Update manual dependency pins outside flake inputs by checking upstream versions, changing repo pins, refreshing hashes, validating, and reporting the result.
compatibility: opencode
metadata:
  audience: maintainers
  repo: nixos
  workflow: dependency-updates
---

## What I do

I update dependencies that are **not** normal flake inputs.

Examples include:

- `fetchurl` downloads with a pinned version in the URL and a pinned hash
- `fetchFromGitHub` derivations pinned to a commit hash and source hash
- container image tags stored in module options or local `version` variables
- manually pinned release versions inside Nix modules
- Firefox addon XPI downloads with explicit addon version and hash
- AppImage downloads with release URLs and hashes

## Companion file

Before doing anything, read `references.md` in this same skill directory.

Treat `references.md` as the registry of known manual dependencies, their upstream locations, how to update them, how to refresh hashes, and how to validate them.

If `references.md` and the repo disagree, trust the repo state for current values and update `references.md` as part of the work.

## When to use me

Use me when the user asks to:

- update manually pinned versions outside `flake.lock`
- check whether repo-local pinned third-party software is stale
- refresh hashes after bumping a URL, tag, release, or revision
- update Docker image tags, AppImage releases, Firefox addon packages, or custom `fetchFromGitHub` pins

Do not use me for standard flake input updates. Use `update-flake-inputs` for those.

## Working style

- Prefer the explicit entries in `references.md` over repo-wide guesswork.
- Keep version discovery and mechanical hash refresh separate in your thinking.
- Update the smallest correct set of fields together: version/rev, URL/image/tag, and hash/digest.
- Never leave a changed source with a stale hash.
- Make targeted edits with minimal unrelated churn.
- Be conservative when the upstream release policy is ambiguous.

## Workflow

1. Read the registry.
   - Open `references.md` in this skill directory.
   - Identify which dependencies are in scope for this run.
   - If no scope is provided, operate on all clearly defined entries.

2. Inspect the current repo state.
   - Open each referenced file.
   - Confirm the current version, rev, URL, image tag, and hash match the registry notes.
   - If the layout drifted, update your understanding from the repo before editing.

3. Check upstream.
   - Use the documented upstream URL from the registry or nearby repo comments.
   - Determine the latest acceptable version according to the dependency’s update rule.
   - If upstream is branch-based, determine the latest acceptable commit according to the documented branch rule.
   - If the notion of “latest” is ambiguous, stop and report instead of guessing.

4. Update the repo pin.
   - Change the version/rev/tag in the Nix file.
   - Update any URL or image string derived from that version.
   - Refresh the corresponding hash or digest.
   - If multiple fields must move together, update them in one coherent edit.

5. Validate.
   - Run the lightest relevant validation first.
   - Prefer file/package/host-specific validation from the registry when available.
   - If validation fails, keep the failure details and do not hide the breakage.

6. Maintain the registry.
   - Update `references.md` if the file path, current version, update notes, or validation command changed.
   - Add concise notes for any quirks discovered during the run.

7. Report.
   - Updated items with old and new values.
   - Hashes refreshed.
   - Validation run and results.
   - Any skipped or ambiguous entries.

## Discovery rules

If the user asks for additional manual dependencies beyond the registry:

- Scan for likely pins such as `version =`, `rev =`, `sha256 =`, `hash =`, `image =`, `fetchurl`, `fetchFromGitHub`, `buildFirefoxXpiAddon`, and explicit release/download URLs.
- Prefer candidates that also have a nearby upstream comment or obvious release URL.
- Add newly confirmed manual dependencies to `references.md`.
- Do not bulk-edit speculative matches.

## Guardrails

- Do not treat every `version =` string as a dependency pin.
- Do not switch source type or refactor the package structure unless asked.
- Do not convert manual pins into flake inputs unless the user asks for a refactor.
- Do not silently widen a pinning policy from release/tag to branch head.
- Do not commit, push, or create PRs unless explicitly asked.

## Standardization rules for this repo

Prefer this structure for future manual pins whenever practical:

- one nearby comment pointing to the upstream releases/packages page
- one obvious local variable or value representing the current version/rev/tag
- one obvious hash field tied to that source
- enough notes in `references.md` to explain how to refresh it
- one validation command per dependency or per dependency family

Do not rewrite working code just to force standardization during a routine update. Only normalize lightly when it reduces future maintenance.

## Output format

Use this structure in the final report:

### Updated manual dependencies
- `<name>`: `<old>` -> `<new>`

### Refreshed source hashes or digests
- `<name>`: `<field>` updated

### Validation
- `<command>`: passed/failed

### Skipped or ambiguous
- `<name>`: `<reason>`

### Registry maintenance
- entries added or notes updated in `references.md`
