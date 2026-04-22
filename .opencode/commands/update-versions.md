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
- `deps`: run only `update-dependencies`
- `scan`: do not change files yet; inspect the repo for version pins outside
  flake inputs and report what should be added to
  `.opencode/skills/update-dependencies/references.md`

General rules:

1. Start by reading `AGENTS.md` if present.
2. Load the relevant skill(s) with the `skill` tool.
3. Follow the loaded skill instructions exactly.
4. Prefer small, reviewable edits.
5. After making changes, run the validation commands required by the skill(s).
6. At the end, report:
   - what changed
   - what was checked but unchanged
   - any failed validations
   - any new dependency patterns that should be added to `references.md`

If mode is `all` or omitted:

- first run `update-flake-inputs`
- then run `update-dependencies`

If mode is `scan`:

- inspect the repo for version pins such as:
  - `version = "..."`
  - `rev = "..."`
  - `image = "...:tag"`
  - `fetchurl`
  - `fetchFromGitHub`
  - Firefox addon XPI URLs
- produce a concise report grouped by file
- propose exact entries to add to
  `.opencode/skills/update-dependencies/references.md`
- do not edit anything unless explicitly asked
