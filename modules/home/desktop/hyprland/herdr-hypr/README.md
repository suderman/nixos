# Herdr and Hyprland pairing trial

A Herdr workspace owns a context. Its paired Hyprland workspace is a changeable
placement, not a permanent number. Only explicitly owned `chromium-agent`
windows participate. There is no workspace-switch synchronization or daemon.
Cog opts in with `programs.herdr-hypr.enable = true`.

## Use

From a Herdr pane, put the desktop on the intended Hyprland workspace:

```sh
herdr-hypr pair                  # Pair with the active Hyprland workspace
chromium-agent --new-window      # Launch or reuse this context's browser
herdr-hypr list                  # Show mappings, labels, and foreground cwd
herdr-hypr goto                  # Explicitly switch to this context's placement
herdr-hypr unpair                # Clear the pairing; leave windows untouched
herdr-hypr cdp                   # Print this context's live CDP endpoint
herdr-hypr cdp --start           # Start it if absent and wait for its endpoint
```

Run `pair` again on another Hyprland workspace to move all existing owned
browser windows and route future windows there. Missing destination workspaces
are created by Hyprland's normal absolute-workspace dispatch.

Herdr's temporary shortcut is **Alt+Z, then Alt+P** (`prefix+alt+p`). It runs
`pair` with Herdr's selected pane context. No global Hyprland binding is added:
a compositor-launched shell does not know which Herdr pane is the caller.

The trial changes Pi's existing `chrome-devtools` MCP launcher to
`herdr-hypr devtools --no-usage-statistics`. Inside Herdr, it starts the owned
browser if absent, waits up to 15 seconds for its endpoint, then connects MCP.
Outside Herdr it keeps port 9222. Existing Pi sessions need `/reload` after
activation. Reconnect `chrome-devtools` through `/mcp` if tools are unavailable
or an existing Pi pane moves to a different Herdr workspace.
Other MCP clients can use:

```sh
endpoint=$(herdr-hypr cdp --start) || exit 1
npx -y chrome-devtools-mcp@latest --browser-url="$endpoint" --no-usage-statistics
```

Direct CDP fallback must use that same resolved endpoint. Never read another
workspace's port file or fall back to 9222 when an owned lookup fails.
`chromium-agent --help` exits without starting a browser. Shared browser skills
in `~/.agents` describe this ownership rule.

## Mechanism and state

The helper uses `HERDR_WORKSPACE_ID`, checked against Herdr's socket API.
When `HERDR_PANE_ID` exists it resolves `pane current --current`, so a moved
pane's stale environment does not become the ownership key. Labels can change.

`workspace report-metadata` stores two tokens, without a TTL, under source
`user:herdr-hypr`:

- `hypr_workspace`: an absolute number, `name:<name>`, or `special:<name>`.
- `hypr_instance`: the current `HYPRLAND_INSTANCE_SIGNATURE`.

Metadata is the only pairing record. The signature prevents a pairing from
routing windows in a later compositor session. Invalid or stale tokens are
ignored. Herdr's metadata CLI returns empty stdout on success; inspection
commands return JSON.

The existing Chromium agent wrapper gains one opt-in branch. In a Herdr pane,
it launches with:

```text
--class=chromium-agent-<socket-generation-hash>-<Herdr-ID>
--user-data-dir=$XDG_RUNTIME_DIR/chromium-agent/<class>
--disk-cache-dir=<profile>/cache
--remote-debugging-port=0
```

The hash uses the canonical socket path, inode, and creation/change timestamp.
It separates named Herdr servers and prevents a restarted server's reused IDs
from adopting old browsers. Chromium's last profile/class switches win over
the wrapper's personal-profile defaults. Same-owner launches reuse one browser;
different owners have separate processes, profiles, and CDP ports. Owned
launches never run the old wrapper's global-browser kill/restart logic.

Chromium clears its process environment and flattens its process command line.
The wrapper therefore creates `<profile>/herdr.sock`, a symlink to the owning
server socket. Routing derives the runtime profile from the exact window class,
checks its singleton-lock PID against the window PID and verifies the
socket-generation hash, then queries that Herdr server's metadata.
The symlink records server identity, not a Hyprland destination. Browser data,
cache, lock files, CDP port file, and this symlink all stay under the intentional
runtime profile. There is no persistent agent-profile data for owned launches.

Native Hyprland Lua handles `window.open` and `window.class`. It starts one short
helper only for matching agent classes. The helper moves a paired window with
`hl.dsp.window.move`, `follow=false`; unpaired and ordinary browser windows are
left alone. No periodic polling, plugin, runtime tags, or extra service is used.
A new window can briefly appear on the launch workspace before the event helper
moves it. Existing-window moves happen explicitly during `pair`.

## Inspect

```sh
printf '%s\n' "$HERDR_WORKSPACE_ID" "$HERDR_PANE_ID" "$HERDR_SOCKET_PATH"
herdr pane current --current
herdr workspace get "$HERDR_WORKSPACE_ID" | jq '.result.workspace | {workspace_id,label,tokens}'
herdr-hypr list
hyprctl -j clients | jq '.[] | {address,class,pid,workspace}'
herdr-hypr route 0xWINDOW_ADDRESS  # One-shot routing probe, or a clear error
herdr-hypr cdp
```

`route` prints the address, Herdr ID, and destination when it moves a window.
Read a browser's `/proc/<pid>/cmdline` and its runtime `herdr.sock` symlink to
check server ownership. `cdp` checks the browser's singleton-lock PID and class
before returning a port, rather than trusting a stale port file. Startup logs
from `cdp --start` and `devtools` are in `<owned-profile>/launch.log`. Failed
startup reports that path and never selects another browser.

## Restart boundaries and limits

- Hyprland reload re-registers hooks and keeps pairings. It does not scan or move
  already-open windows; `pair` does that explicitly.
- Herdr server restart loses tokens. A new socket generation gives new browser
  identities. Old windows remain where they were and are not adopted.
- A later compositor signature invalidates tokens surviving in a still-running
  Herdr server. Cog has user lingering enabled, so logout does not guarantee
  removal of runtime profiles. They last until the user runtime directory is
  removed, normally at reboot or when the user manager stops.
- NixOS/Home Manager rebuild keeps live metadata and browser processes. Reload
  Hyprland after changing feature snippets. New Pi connections use the new
  launcher; already-connected MCP servers do not retarget themselves.
- Cog's scheduled upgrade uses `github:suderman/nixos#cog`, not this local
  checkout. Until the trial is published upstream, that upgrade can remove the
  helper and restore global MCP settings. Reapply this checkout to resume the
  trial. Publishing or changing upgrade policy requires a separate decision.
- Closing/reopening an owned browser keeps its disposable runtime profile and
  current pairing. Closing a browser does not remove its profile.
- Only local Wayland agent Chromium windows are tested. Other browsers, remote
  Herdr servers, app-mode/PWA windows, editors, and terminal ownership are out of
  scope. Short title/class transitions are handled by native open/class events.
- Owned profiles do not inherit personal logins or the old global agent profile.
  The old global profile and port 9222 remain available outside Herdr.
- Sidebar token presentation is supported by Herdr (`$hypr_workspace`) but is
  deferred to avoid changing existing row layout during the routing trial.

## Disable or remove

Set `programs.herdr-hypr.enable = false` on Cog, rebuild, then reload Hyprland.
The browser wrapper returns to its existing global behavior; no new windows
are routed. Pi's normal bootstrap restores the original MCP configuration on
activation. Disable does not kill existing owned browsers or delete metadata.
Run `unpair` first in any contexts whose tokens should be cleared. Close owned
browsers normally. Their runtime profiles disappear when the user runtime
directory is removed; with Cog's user lingering, that may require a reboot.

To remove the trial entirely, also delete this module folder, its flake check,
and the small conditional branch in `chromium/agents.nix`.

Run the targeted declarative check with:

```sh
nix develop --command nix build .#checks.x86_64-linux.herdr-hypr -L
```
