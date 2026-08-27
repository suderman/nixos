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

Jon's configuration on `kit` also runs the command at 04:00 and 16:00 through
`fresha-org.timer`. The service renders into a temporary file and atomically
replaces `~/org/fresha.org` only after a successful run. Browser, login, network,
or Fresha errors leave the previous schedule in place. If Chromium's CDP port is
not available, the service launches `chromium-agent` through Hyprland and waits
for it before fetching the schedule.

Example output:

```org
* Clinic on Friday at 11:30am
<2026-08-28 Fri 11:30-18:00>
Open in Fresha: https://partners.fresha.com/calendar?date=2026-08-28

- Jennifer 11:30-18:00
```

The script queries today through 35 days ahead. Each event spans the earliest
staff start through the latest finish and lists every effective shift. Approved
time off and location closures remove coverage. Event headings use the earliest
start time, and each event links directly to that date in the Fresha calendar.

## Requirements

- `chromium-agent` running on CDP port 9222
- A valid Fresha login in that Chromium profile

The module runs the script with Node.js 24. An open Fresha tab is optional. If
none exists, the script opens the calendar in a background tab. It does not
automate login.
