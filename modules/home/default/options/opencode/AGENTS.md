# Agent Rules and Engineering Conventions

## Purpose

This document defines baseline conventions and expectations for all agents
contributing to any project. Treat it as a living document. Use it as a starting
point, not a single source of truth.

---

## Core principles

- **Complexity is the primary enemy.** Prefer simple, clear, and maintainable
  solutions over clever or abstract ones.
- Write code for humans first, machines second.
- Saying no to unnecessary features, abstractions, or rewrites is encouraged.
- If progress would otherwise stall, proceed with the smallest reversible
  change.
- Prefer explicit behavior over implicit assumptions.
- Follow the principle of least surprise: code should behave as most users
  expect.
- Prefer idempotent and stateless designs when they do not significantly
  increase complexity.
- Avoid premature optimization.
- Program defensively.
- Treat warnings and errors as bugs, not noise.

---

## Decision and permission model

- If uncertainty materially affects architecture, security, data integrity, or
  public APIs, ask for clarification.
- Otherwise, proceed with the smallest safe and reversible change.
- Prefer incremental changes over large refactors unless explicitly requested.

---

## Agent-specific behavior

- Prefer minimal diffs over broad rewrites.
- Do not refactor unrelated code unless explicitly requested.
- Preserve existing project conventions unless explicitly instructed to change
  them.
- When multiple solutions exist, choose the simplest viable one.
- Explain reasoning briefly before making non-trivial changes.
- Avoid introducing new dependencies unless clearly justified.

---

## Tool usage

- Prefer Context7 when working with unfamiliar libraries, APIs, frameworks, or
  unclear documentation.
- Use Context7 to resolve `libraryId` and retrieve authoritative documentation
  when needed.
- Use `gh_grep` when official documentation is insufficient, ambiguous, or
  incomplete.
- Do not fetch external documentation unnecessarily when the solution is already
  clear from context.

---

## Commit message conventions

Follow the Conventional Commits specification unless a project defines its own
rules.

Additional guidelines:

- Use the imperative mood (e.g. “add”, not “adds” or “added”).
- Use lowercase in the commit summary.
- Do not end the summary with a period.
- Keep the summary concise and ideally under 72 characters.
- Use plain ASCII characters in commit messages.
- Use a commit body when context, rationale, or consequences are non-obvious.

### Examples

#### Commit message with no body

```
docs: correct spelling of changelog
```

#### Commit message with scope

```
feat(lang): add polish language
```

#### Commit message with body and footers

```
fix: prevent request race conditions

Introduce request ids and track the latest request. Ignore responses
from outdated requests.

Remove timeouts that previously masked the issue.

Reviewed-by: Z
Refs: #123
```

---

## Security considerations

- Never log sensitive data (credentials, secrets, PII).
- Avoid adding new dependencies when existing libraries or the standard library
  are sufficient.
- Assume external input may be malicious until validated.
- Validate data for correctness, not merely absence of errors.
- Use assertions when supported by the language or runtime.
- Treat external data as tainted until verified.
- Do not destroy or mutate data unless it has been explicitly verified as safe
  to discard.
- Do not assume code is secure without explicit reasoning or review.

---

## Engineering bias

- Prefer clarity over cleverness.
- Prefer local reasoning over global abstractions.
- Prefer reversible changes over irreversible ones.
- Prefer boring solutions over novel ones unless novelty is explicitly required.
