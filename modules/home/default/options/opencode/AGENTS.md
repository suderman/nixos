## Purpose

This document defines baseline conventions and expectations for all agents
contributing to any project. Treat this as a living document -- expect things to
change with time. Use this doc as a starting point, but do not treat it as the
single source of truth.

## General guidelines

- **Complexity is your arch-nemesis**. Write clear, maintainable, and minimal
  code. Avoid unnecessary abstractions. You’re writing code for humans first,
  computers second.
- Saying no (to a feature or abstraction or rewrite) is OK.
- Sometimes you have no choice but to say OK because otherwise it halts all
  progress.
- **Easier to ask for permission than to repair the damage**. Unless you are
  explicitly given permission, always ask before committing to something.
- **Always favor being explicit over implicit**.
- **Follow the principle of least surprise** -- your code should behave in a way
  that most users will expect it to behave, and therefore not astonish or
  surprise users.
- Default to idempotent operations and stateless design when possible.
- **Avoid premature optimization**.
- Always program defensively (more under #security-considerations).
- **Treat warnings and errors as bugs to fix, not noise to ignore.**
- Always use `context7` tools when you need code generation, setup or
  configuration steps, or documentation. Automatically use the Context7 MCP
  tools to resolve the `libraryId` and get library docs without me having to
  explicitly ask.
- If you are unsure how to do something, use `gh_grep` to search code examples
  from GitHub.

## Writing good commit messages

Follow the
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification)
spec when writing commit messages, unless a project defines its own guidelines.

Additionally:

- Description should be concise and in the imperative mood (e.g. “add”, not
  “adds” or “added”).
- Only use lowercase for the commit summary.
- No period at the end of the commit summary.
- The commit summary should not exceed 75 characters (if at all possible).
- You can write a longer commit body in addition to the
- Always use smart quotes

### Examples

#### Commit message with no body

```
docs: correct spelling of CHANGELOG
```

#### Commit message with scope

```
feat(lang): add Polish language
```

#### Commit message with multi-paragraph body and multiple footers

```
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Reviewed-by: Z
Refs: #123
```

## Security considerations

- **Never** log sensitive data (credentials, PII, secrets).
- Do **not** install any new dependencies if the task can be achieved using
  existing libraries (standard lib or existing dependencies).
- You must assume that your code might be misused actively to reveal bugs, and
  that bugs could be exploited maliciously.
- If data is to be checked for correctness, verify that it is correct, not that
  it is incorrect.
- Use assertions if the programming language (or runtime) supports them.
- **All data is important until proven otherwise** -- all data must be verified
  as garbage before being destroyed.
- **All data is tainted until proven otherwise** -- all data must be handled in
  a way that does not expose the rest of the runtime environment without
  verifying integrity.
- **All code is insecure until proven otherwise** -- never assume your code is
  secure as bugs or undefined behavior may expose the project or system to
  attacks such as common SQL injection attacks.
