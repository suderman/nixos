---
description: Update flake inputs, repo-pinned dependencies, or both
subtask: true
---

You are performing version-maintenance work in this repository.

Requested mode: `$1` Extra instructions: `$ARGUMENTS`

Interpret the requested mode like this:

- empty, `all`, or omitted: run both `update-flake-inputs` and
  `update-dependencies`
- `flake`: run only `update-flake-inputs`
- `flake-full` or `flake-heavy`: run only `update-flake-inputs` and require full build-heavy validation
- `deps`: run only `update-dependencies`
- `all-full` or `all-heavy`: run both `update-flake-inputs` and `update-dependencies`, and require full build-heavy validation for the flake-input phase
- `scan`: do not change files yet; inspect the repo for version pins outside
  flake inputs and report what should be added to
  `.opencode/skills/update-dependencies/references.md`

General rules:

1. Start by reading `AGENTS.md` if present.
2. Load the relevant skill(s) with the `skill` tool.
3. Follow the loaded skill instructions exactly.
4. Prefer the deterministic helpers in `.opencode/scripts/update-versions/` when they fit:
   - `pick-flake-validation.py` to choose the cheapest relevant validation host
   - `scan-manual-pins.py` for `scan` mode or registry discovery work
5. Prefer small, reviewable edits.
6. After making changes, run the validation commands required by the skill(s).
   - For `update-flake-inputs`, prefer the skill's quick validation by default.
   - Run full build-heavy validation when the selected mode is `flake-full`, `flake-heavy`, `all-full`, or `all-heavy`.
   - Otherwise only run full build-heavy validation when explicitly requested or clearly warranted.
7. At the end, report:
   - what changed
   - what was checked but unchanged
   - which validations were quick vs full, and any failed validations
   - any new dependency patterns that should be added to `references.md`

If mode is `all`, `all-full`, `all-heavy`, or omitted:

- first run `update-flake-inputs`
- then run `update-dependencies`
- require full build-heavy validation for the flake-input phase only when mode is `all-full` or `all-heavy`
- otherwise do not automatically escalate the flake-input phase from quick validation to full build-heavy validation unless the user asked for it

If mode is `flake-full` or `flake-heavy`:

- run only `update-flake-inputs`
- require full build-heavy validation for that phase

If mode is `scan`:

- start with `python3 .opencode/scripts/update-versions/scan-manual-pins.py`
- use follow-up reads/searches only to confirm likely matches from that scan
- produce a concise report grouped by file
- propose exact entries to add to
  `.opencode/skills/update-dependencies/references.md`
- do not edit anything unless explicitly asked
