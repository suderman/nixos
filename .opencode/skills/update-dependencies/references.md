# Manual dependency registry

This file is read by the `update-dependencies` skill.

Use it as the source of truth for dependency **shape** and update procedure, while treating the repo files themselves as the source of truth for the **current pinned values**.

## How to maintain this file

For each manual dependency, keep:

- `name`: stable human-readable label
- `kind`: one of `firefox-xpi`, `fetchurl-release`, `fetch-github-rev`, `container-tag`, `manual-version`
- `file`: repo path to edit
- `lookup`: how to find the pin in the file
- `upstream`: canonical page to check for new versions
- `update_rule`: what counts as the next acceptable version
- `hash_rule`: how the source hash is refreshed
- `validate`: the lightest useful validation command or check
- `notes`: quirks that make this dependency easier to maintain next time

---

## easy-container-shortcuts

- name: easy-container-shortcuts
- kind: firefox-xpi
- file: modules/home/desktop/default/options/firefox/addons.nix
- lookup: `config.programs.firefox.extraAddons.easy-container-shortcuts`
- current_fields:
  - `version = "1.8.0"`
  - `url = ".../easy_container_shortcuts-1.8.0.xpi"`
  - `sha256 = "0ybczzi7ba2yix945dh3k4ipy63f01kszwq0207cvxckk9gy3pxc"`
- upstream: https://addons.mozilla.org/en-US/firefox/addon/easy-container-shortcuts/
- update_rule: use the newest stable addon release on the addon page that matches the XPI download pattern already used here
- hash_rule: after changing the XPI URL, refresh the source hash for the downloaded XPI and update `sha256`
- validate: `nix develop -c nix eval .#nixosConfigurations.kit.config.system.build.toplevel.outPath`
- notes:
  - version appears in more than one place and must move together
  - keep `addonId` unchanged unless upstream addon identity changed

## eden-appimage

- name: eden-appimage
- kind: fetchurl-release
- file: modules/home/desktop/default/options/eden.nix
- lookup: `package = pkgs.stdenv.mkDerivation { ... version = ...; src = pkgs.fetchurl { ... } }`
- current_fields:
  - `version = "0.2.0-rc2"`
  - `url = "https://git.eden-emu.dev/eden-emu/eden/releases/download/v0.2.0-rc2/Eden-Linux-v0.2.0-rc2-amd64-gcc-standard.AppImage"`
  - `sha256 = "sha256-1Pp6VInWYfr8f8ANuT1ZBxe61xCWcTq/mNH8T6JZJJc="`
- upstream: https://git.eden-emu.dev/eden-emu/eden/releases
- update_rule: prefer the latest acceptable Linux AppImage release; if the repo is intentionally on release candidates, do not automatically jump from RC to stable or vice versa without making that explicit in the report
- hash_rule: after changing the release URL, refresh the fetchurl hash and update `sha256`
- validate: `nix develop -c nix eval .#nixosConfigurations.kit.config.system.build.toplevel.outPath`
- notes:
  - the version appears in both the local `version` field and the download URL
  - preserve the existing AppImage filename pattern unless upstream changed it

## mpd-url

- name: mpd-url
- kind: fetch-github-rev
- file: packages/mpd-url.nix
- lookup: `pkgs.fetchFromGitHub { owner = "suderman"; repo = "mpd-url"; rev = ...; sha256 = ...; }`
- current_fields:
  - `rev = "09200dd2dbc3d51312cbf5881efc00678dce9a11"`
  - `sha256 = "sha256-Wcl+wenrdkGOcjwFEmhCIVHIoZs97oMOrJzP1fbxtUE="`
- upstream: https://github.com/suderman/mpd-url
- update_rule: default to the latest commit on the tracked default branch unless this package is intentionally pinned for a reason noted in the repo
- hash_rule: after changing `rev`, refresh the fetched source hash and update `sha256`
- validate: `nix develop -c nix build .#packages.x86_64-linux.mpd-url`
- notes:
  - branch-based pins are higher risk than tagged releases; call this out in the report

## home-assistant

- name: home-assistant
- kind: container-tag
- file: modules/nixos/default/options/home-assistant/default.nix
- lookup: `version = ...`
- current_fields:
  - `version = "2026.4.3"`
- upstream: https://github.com/home-assistant/core/pkgs/container/home-assistant/versions?filters%5Bversion_type%5D=tagged
- update_rule: use the newest tagged container version that matches the policy already used in this repo
- hash_rule: no source hash in this file; update only the tag unless the repo later starts pinning digests
- validate: `nix develop -c nix eval .#nixosConfigurations.hub.config.system.build.toplevel.outPath`
- notes:
  - confirm where the version variable is consumed before editing adjacent code

## zwave-js-ui

- name: zwave-js-ui
- kind: container-tag
- file: modules/nixos/default/options/home-assistant/default.nix
- lookup: `zwaveVersion = ...`
- current_fields:
  - `zwaveVersion = "11.16.1"`
- upstream: https://github.com/zwave-js/zwave-js-ui/pkgs/container/zwave-js-ui/versions?filters%5Bversion_type%5D=tagged
- update_rule: use the newest tagged container version that matches the policy already used in this repo
- hash_rule: no source hash in this file; update only the tag unless the repo later starts pinning digests
- validate: `nix develop -c nix eval .#nixosConfigurations.hub.config.system.build.toplevel.outPath`
- notes:
  - keep this aligned with the surrounding Home Assistant module expectations

## immich

- name: immich
- kind: manual-version
- file: modules/nixos/default/options/immich.nix
- lookup: `version = ...`
- current_fields:
  - `version = "2.7.5"`
- upstream: https://github.com/immich-app/immich/releases
- update_rule: use the newest stable tagged release unless the repo intentionally tracks prereleases
- hash_rule: no inline source hash shown in this file snippet; update any related tag or image reference in the same module if present
- validate: `nix develop -c nix eval .#nixosConfigurations.sim.config.system.build.toplevel.outPath`
- notes:
  - search the module for all usages of `version` before editing

## codex-lb

- name: codex-lb
- kind: container-tag
- file: modules/nixos/default/options/codex-lb.nix
- lookup: `version = ...` and `image = "ghcr.io/soju06/codex-lb:${cfg.version}"`
- current_fields:
  - `version = "1.14.1"`
  - `image = "ghcr.io/soju06/codex-lb:${cfg.version}"`
- upstream: https://github.com/Soju06/codex-lb/pkgs/container/codex-lb
- update_rule: use the newest tagged container version compatible with the repo’s existing policy
- hash_rule: no source hash in this file; update only the tag unless the repo later starts pinning digests
- validate: `nix develop -c nix eval .#nixosConfigurations.kit.config.system.build.toplevel.outPath`
- notes:
  - the image string is derived from `cfg.version`; usually only the version default needs changing

## citron-appimage

- name: citron-appimage
- kind: fetchurl-release
- file: modules/home/desktop/default/options/citron.nix
- lookup: `package = pkgs.stdenv.mkDerivation { ... version = ...; src = pkgs.fetchurl { ... } }`
- current_fields:
  - `version = "0.12.25"`
  - `url = "https://git.citron-emu.org/Citron/Emulator/releases/download/0.12.25/citron_stable-01c042048-linux-x86_64_v3.AppImage"`
  - `sha256 = "G0yX6ZP6f9nDY41VS8k/UVduoTsZLFrAduA5mOD3OmY="`
- upstream: https://git.citron-emu.org/Citron/Emulator/releases
- update_rule: prefer the latest acceptable Linux AppImage release that matches the repo's existing stable Citron packaging pattern
- hash_rule: after changing the release URL, refresh the fetchurl hash and update `sha256`
- validate: `nix develop -c nix eval .#nixosConfigurations.kit.config.system.build.toplevel.outPath`
- notes:
  - the version appears in both the local `version` field and the download URL
  - preserve the existing AppImage filename pattern unless upstream changed it

## chromium-web-store

- name: chromium-web-store
- kind: manual-version
- file: modules/home/desktop/default/options/chromium/registry.nix
- lookup: `chromium-web-store = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v.../Chromium.Web.Store.crx"`
- current_fields:
  - `url = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx"`
- upstream: https://github.com/NeverDecaf/chromium-web-store/releases
- update_rule: use the newest stable CRX release URL that preserves the existing download pattern unless the browser-side installation flow changes
- hash_rule: no inline source hash in this file; update only the release URL unless the repo later starts pinning a CRX hash
- validate: evaluate the smallest desktop host that imports this chromium registry, for example `nix develop -c nix eval .#nixosConfigurations.cog.config.system.build.toplevel.outPath`
- notes:
  - this registry stores the CRX URL directly rather than splitting out a separate version field
  - keep the extension id mapping behavior unchanged; only the release URL should move during routine updates

## backblaze-personal-wine

- name: backblaze-personal-wine
- kind: container-tag
- file: modules/nixos/default/options/backblaze.nix
- lookup: `version = ...` and `image = "tessypowder/backblaze-personal-wine:v${version}"`
- current_fields:
  - `version = "1.9"`
  - `image = "tessypowder/backblaze-personal-wine:v${version}"`
- upstream: https://hub.docker.com/r/tessypowder/backblaze-personal-wine/tags
- update_rule: use the newest tagged container version compatible with the repo's existing policy
- hash_rule: no source hash in this file; update only the tag unless the repo later starts pinning digests
- validate: `nix develop -c nix eval .#nixosConfigurations.lux.config.system.build.toplevel.outPath`
- notes:
  - the image tag is derived from the local `version` binding
  - confirm the upstream container still uses the same volume and environment conventions before bumping

## rsshub

- name: rsshub
- kind: container-tag
- file: modules/nixos/default/options/rsshub.nix
- lookup: `tag = ...` and `image = "diygod/rsshub:${cfg.tag}"`
- current_fields:
  - `tag = "chromium-bundled"`
  - `image = "diygod/rsshub:${cfg.tag}"`
- upstream: https://hub.docker.com/r/diygod/rsshub/tags
- update_rule: use the newest acceptable tag that matches the repo's chosen RSSHub flavor; do not silently switch away from `chromium-bundled` to another variant
- hash_rule: no source hash in this file; update only the tag unless the repo later starts pinning digests
- validate: evaluate the smallest NixOS target that uses this module; default to `nix develop -c nix eval .#nixosConfigurations.hub.config.system.build.toplevel.outPath`
- notes:
  - `chromium-bundled` is a flavor choice, not just a version string
  - keep the docker network and companion redis container assumptions aligned with the chosen image tag

## rsshub-redis

- name: rsshub-redis
- kind: container-tag
- file: modules/nixos/default/options/rsshub.nix
- lookup: `image = "redis:6.2"`
- current_fields:
  - `image = "redis:6.2"`
- upstream: https://hub.docker.com/_/redis/tags
- update_rule: use the newest acceptable Redis tag compatible with the RSSHub setup in this repo; prefer conservative major-version changes
- hash_rule: no source hash in this file; update only the tag unless the repo later starts pinning digests
- validate: evaluate the smallest NixOS target that uses this module; default to `nix develop -c nix eval .#nixosConfigurations.hub.config.system.build.toplevel.outPath`
- notes:
  - this is a companion container pin for RSSHub rather than a standalone service module version binding
  - treat Redis major-version bumps as higher risk than patch/minor tag updates

## whoogle-search

- name: whoogle-search
- kind: container-tag
- file: modules/nixos/default/options/whoogle.nix
- lookup: `version = ...` and `image = "benbusby/whoogle-search:${version}"`
- current_fields:
  - `version = "0.9.4"`
  - `image = "benbusby/whoogle-search:${version}"`
- upstream: https://github.com/benbusby/whoogle-search/releases
- update_rule: use the newest tagged release compatible with the repo's existing policy
- hash_rule: no source hash in this file; update only the tag unless the repo later starts pinning digests
- validate: `nix develop -c nix eval .#nixosConfigurations.cog.config.system.build.toplevel.outPath`
- notes:
  - the image tag is derived from the local `version` binding
  - the module may be disabled on some hosts but the pin is still a tracked maintenance target

---

## Explicit non-tracked pin policies

- `modules/nixos/default/options/unifi.nix`:
  - keep `version = "7.5"` pinned permanently unless the user explicitly asks to revisit that policy
  - do not add Unifi as a routine auto-update target in this registry

## Candidate patterns to discover later

These are not confirmed entries yet. Promote them into full entries only after checking the repo:

- `fetchurl { url = ...; sha256 = ...; }`
- `fetchFromGitHub { rev = ...; sha256 = ...; }`
- `buildFirefoxXpiAddon { version = ...; url = ...; sha256 = ...; }`
- `image = "ghcr.io/...:${...}"`
- standalone `version = "..."` values with a nearby upstream release comment
