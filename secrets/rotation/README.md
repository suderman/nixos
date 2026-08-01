# Identity rotation preflight

No root rotation is active. This directory documents the transition contract
before any next-root material is created.

## Safety marker

Create `secrets/rotation/ACTIVE` in the rotation commit before preparing or
deploying transition artifacts. While it exists, the normal wrappers refuse
commands that can rewrite identity state fleet-wide:

- `nixos add`
- `nixos generate`
- `agenix import`
- `agenix rekey -a`
- `agenix update-masterkeys`

The future managed rotation workflow may set `IDENTITY_ROTATION_ALLOW=1` only
around its validated, phase-specific operations. Do not use that override to
run the blocked commands manually.

## Rotation scope

This is a routine BIP-85 index rotation, not compromise recovery. The planned
transition keeps the current fleet-global v1 derivation model. Versioned domain
separation and per-host roots remain separate future work.

The transition must:

- retain the current root and master identity until every target is verified
- use explicit current and next paths instead of `/tmp/id_age_`
- stage both host keys in system known-hosts trust and `sshed` verification
- stage both user age and SSH identities, including Btrbk and Beszel
- rotate machine IDs and the Arr API keys derived from them
- keep plaintext roots and private identities out of Git and logs
- support prepare, partial rollout, rollback, resume, and finalize in an
  isolated simulation before touching a live target

Matrix Synapse and Hermes' Matrix integration are disabled before rotation, so
their experimental persistent credentials are not part of the migration.

## Active target snapshot

The repository structure remains the source of truth. This snapshot exists to
make omissions visible while the transition model is developed.

NixOS secret targets:

- `cog`
- `eve`
- `hub`
- `kit`
- `lux`
- `pow`
- `sim`
- `wit`

Home Manager secret targets:

- `cog-jon`
- `eve-jon`
- `hub-jon`
- `kit-jon`
- `lux-jon`
- `pow-jon`
- `sim-jon`
- `wit-jon`

Additional Home Manager identities without generated secret ciphertext:

- `cog-ness`
- `wit-ness`

Derived user and service identities:

- `root`
- `jon`
- `ness`
- `btrbk`
- `beszel`

Generated outputs for removed `fit`, `fit-jon`, and `kit-bot` targets were
deleted during preflight and must not reappear.

## Remaining blockers

Do not create index-2 artifacts until these are implemented and tested:

- an isolated current/next root fixture for simulation
- a per-target current/next state manifest
- dual host-key paths, known-host entries, and rollback-safe `sshed` behavior
- dual NixOS and Home Manager age identity paths
- dual login, Btrbk, and Beszel SSH authorization
- migration checks for machine IDs, Arr, MQTT, Hermes, Camofox, and other
  derived runtime credentials
