# fresha-org

This Home Manager module packages `fresha-org`, which reads staff shifts through
the user's Fresha session in `chromium-agent` and writes Org events to stdout.

Enable it for a Home Manager user:

```nix
programs.fresha-org.enable = true;
```

Then write the schedule to an Org file manually:

```sh
fresha-org > ~/org/fresha.org
```

Example output:

```org
#+title: Fresha clinic schedule
#+category: Clinic

* Clinic
  <2026-08-28 Fri 11:30-18:00>
  - Jennifer 11:30-18:00
```

The script queries today through 35 days ahead. Each event spans the earliest
staff start through the latest finish and lists every effective shift. Approved
time off and location closures remove coverage.

## Requirements

- `chromium-agent` running on CDP port 9222
- A valid Fresha login in that Chromium profile

The module runs the script with Node.js 24. An open Fresha tab is optional. If
none exists, the script opens the calendar in a background tab. It does not
automate login.

The executable is vendored from `/home/jon/src/suderman/fresha-org`. Update the
source repository first, then copy the tested executable here.

This uses Fresha's unsupported internal APIs. Fresha's terms prohibit automated
scripts and scraping. Manual, low-frequency runs do not remove the account
risk.
