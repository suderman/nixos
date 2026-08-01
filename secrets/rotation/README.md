# Identity rotation preflight

No root rotation is active. This directory contains the inert transition state
and validation scaffold used before any next-root material is created.

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

## State manifest

`state.json` is the non-secret transition ledger. Repository structure remains
authoritative for target membership; the identity-rotation check rejects
missing or stale NixOS, Home Manager, and user/service identity entries.

The idle contract is:

- `status` is `idle`
- `currentIndex` matches `flake.derivationIndex`
- `nextIndex` is `null`
- every target is `current`
- `secrets/rotation/ACTIVE` does not exist

An active transition requires the marker, a distinct `nextIndex`, and a state
for every target. A target must move through `current`, `bridge`, and `next` one
step at a time. Moving backward one step supports rollback. Active mode can end
only after every target has returned to `current`, or after every target has
reached `next` and `nextIndex` is promoted to `currentIndex`.

The validator only reads manifests and repository paths. It does not decrypt,
derive, generate, rekey, or deploy identity material.

Run the focused check with:

```sh
nix build 'path:.#checks.x86_64-linux.identity-rotation' -L
```

The `path:.` form includes uncommitted scaffold changes while developing them.

## Test fixtures

`fixtures/current.hex` and `fixtures/next.hex` are public, fixed test vectors.
They are not BIP-85 wallet output and must never be used outside the test. The
two-target simulator derives exact SSH, age, and machine-ID vectors for `alpha`
and `beta` only in a temporary directory.

The simulator proves the manifest rules for prepare, partial rollout, rollback,
resume, and finalize, including rejection of skipped and inconsistent states.
It does not yet prove NixOS activation, persistent host-key rollback, or secret
decryption in a running VM.

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

The repository structure remains the source of truth. The manifest mirrors this
snapshot, and the flake check enforces that they remain synchronized.

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

Do not create production index-2 artifacts until these are implemented and
tested:

- dual host-key paths, known-host entries, and rollback-safe `sshed` behavior
- dual NixOS and Home Manager age identity paths
- dual login, Btrbk, and Beszel SSH authorization
- migration checks for machine IDs, Arr, MQTT, Hermes, Camofox, and other
  derived runtime credentials
- a two-node NixOS VM test covering bridge deployment and persistent-key
  rollback
