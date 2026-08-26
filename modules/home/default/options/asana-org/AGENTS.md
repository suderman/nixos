# Asana Org Home Manager module

This directory defines the reusable `services.asana-org` Home Manager module.
It mirrors incomplete Asana My Tasks into a managed block in an Org file.

## Files

- `default.nix` defines the options, package, agenix secret, and systemd user
  service and timer.
- `asana-org.py` contains the stdlib-only API client and Org renderer.

Kit/Jon's concrete settings live in
`hosts/kit/users/jon/asana-org.nix`. Keep host-specific workspace, Org path,
heading, and secret values out of this shared module.

## Behavior to preserve

- Sync only incomplete tasks assigned to the authenticated user in the
  configured Asana workspace.
- Initial sync must not backfill completed task history.
- A task first seen while incomplete stays in Org as `DONE` after Asana marks it
  complete.
- Treat Asana as authoritative for active task status and details.
- Replace only the content between `# asana-org:begin` and `# asana-org:end` in
  the configured Org file. The old `asana-to-org` markers are accepted only for
  migration.
- Require the configured Org heading path to exist exactly once. When the path
  changes within the same file, move the complete managed block atomically.
- Keep writes atomic and skip byte-identical updates. Jon's `~/org` is Syncthing
  managed, so his timer must remain enabled on kit only.
- Fetch and validate all required API data before writing. API, token, marker,
  or parsing errors must leave `todo.org` unchanged.
- Do not add an Asana SDK or other Python dependency. The standard library is
  enough for this script.

## Secret handling

Never decrypt, print, log, or request a PAT through agent tools or chat. For the
kit/Jon instance, the user must enter it directly with:

```sh
nix develop -c agenix edit hosts/kit/users/jon/asana-org-token.age
```

The decrypted secret contains only the raw PAT on one line. It must not contain
`ASANA_TOKEN=`, quotes, or comments. After editing it, run:

```sh
nix develop -c agenix rekey -a
```

Do not manually edit the generated ciphertext under
`secrets/home/kit-jon/`. Never create or commit a plaintext token file.

## Verification

Run the narrow checks first:

```sh
python3 modules/home/default/options/asana-org/asana-org.py --self-test
PYTHONPYCACHEPREFIX=/tmp/asana-org-pycache python3 -m py_compile \
  modules/home/default/options/asana-org/asana-org.py
nix fmt -- modules/home/default/options/asana-org/default.nix \
  modules/home/default/options/asana-org/asana-org.py \
  hosts/kit/users/jon/asana-org.nix
nix eval 'path:.#nixosConfigurations.kit.config.system.build.toplevel.outPath'
```

Use `path:.` while files are untracked so Nix includes them. After activation,
the user can run `asana-org` twice; the second run should report no changes.
Do not run a live sync until the user has populated and rekeyed the secret.
