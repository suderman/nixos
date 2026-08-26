# fresha-org Home Manager module

## Goal

Maintain a small Home Manager module that installs the vendored `fresha-org`
command for selected users. The command reads staff working hours from the
user's logged-in Fresha browser session and writes Org events to stdout.

Jon's `kit` instance is enabled in
`hosts/kit/users/jon/home-configuration.nix`.

## Files

- `default.nix` defines `programs.fresha-org.enable` and wraps the script with
  Node.js 24.
- `fresha-org` is vendored from `/home/jon/src/suderman/fresha-org/fresha-org`.
- `README.md` documents activation, usage, and runtime requirements.

## Updating the vendor copy

Treat `/home/jon/src/suderman/fresha-org` as the source of truth. Make and test
runtime changes there first, then copy the executable here unchanged. Confirm
the two files are identical before finishing.

Do not add a timer or redirect stdout in the module. The command remains
manual, and callers choose the destination Org file.

## Runtime constraints

- Use Node.js 24 built-ins only. Add no dependencies.
- Keep Fresha cookies in Chromium. Never persist or print cookies or
  authorization headers.
- If no Fresha page exists, open one in the background using the same Chromium
  profile. Never automate login.
- Write only valid Org text to stdout. Write errors to stderr and exit nonzero.
- Treat Fresha response-shape changes and expired login as hard errors.
- Make no more Fresha requests than a normal calendar load needs. Do not add
  retries or evasive behavior.
- Keep `fresha-org --test` as the focused runnable check.

## Output

- Query today through 35 days ahead in `America/Edmonton`.
- Emit one `Clinic` heading per local date with effective shifts.
- Use an active Org timestamp spanning the earliest start through latest finish.
- Put one staff shift per bullet, ordered by start time.
- Approved time off and location closures remove effective coverage. Ordinary
  blocked time does not.

## Verification

Run from `/etc/nixos`:

```sh
cmp modules/home/default/options/fresha-org/fresha-org \
  /home/jon/src/suderman/fresha-org/fresha-org
node --check modules/home/default/options/fresha-org/fresha-org
node modules/home/default/options/fresha-org/fresha-org --test
nix fmt -- modules/home/default/options/fresha-org/default.nix \
  modules/home/default/options/fresha-org/README.md \
  modules/home/default/options/fresha-org/AGENTS.md \
  hosts/kit/users/jon/home-configuration.nix
nix eval 'path:.#nixosConfigurations.kit.config.system.build.toplevel.outPath'
```

## Risk

This project uses unsupported Fresha internal APIs and may conflict with
Fresha's terms. Keep execution manual, low-frequency, and fail closed if the API
changes.
