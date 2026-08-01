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

The managed rotation workflow may eventually set `IDENTITY_ROTATION_ALLOW=1`
only around validated, phase-specific cryptographic operations. Do not use that
override to run the blocked commands manually.

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

An active transition requires the marker, a non-negative `nextIndex`, and a
state for every target. A target must move through `current`, `bridge`, and
`next` one step at a time. Moving backward one step supports rollback. Active
mode can end only after every target has returned to `current`, or after every
target has reached `next` and `nextIndex` is promoted to `currentIndex`.

The indexes are operator-declared BIP-85 recovery metadata, not cryptographic
generation counters. The repository cannot verify which mnemonic and index
produced a supplied root. Routine rotations normally increment the index, while
a new mnemonic may reset or reuse an index. Preparation proves that a root
generation changed by validating distinct master, host, and user public
identities, not by comparing index numbers.

The validator only reads manifests and repository paths. It does not decrypt,
derive, generate, rekey, or deploy identity material.

## Managed state commands

The `nixos rotation` command owns marker and ledger changes. It never uses the
rotation guard override and never reads plaintext identity material.

```sh
nixos rotation status
nixos rotation prepare 2
nixos rotation move nixos kit bridge
nixos rotation move nixos kit next
nixos rotation move nixos kit bridge
nixos rotation move nixos kit current
nixos rotation cancel
```

`prepare` works only from a valid idle ledger. Before entering active state it
requires a complete non-empty next artifact set, verifies every next public key
is a valid age recipient or Ed25519 SSH key and differs from its canonical key,
and requires valid age ciphertext plus exactly one generated `hex-next`
ciphertext per NixOS target. It then creates the safety marker before atomically
replacing `state.json` and stages the complete preparation set.

`move` changes exactly one target by one adjacent state and atomically replaces
the manifest only after validating repository membership and the transition.
It cannot skip `bridge` or mutate derivation indexes.

`cancel` succeeds only after every target has returned to `current`. It writes
the idle ledger before removing the marker, so an interruption remains guarded.
It can also remove a marker left by an interrupted prepare whose manifest is
still valid and idle. Next artifacts are retained for explicit review or secure
cleanup; cancellation does not silently delete cryptographic material.

There is intentionally no usable `finalize` command yet. Finalization must
promote the master identity, root ciphertext, canonical public keys, generated
ciphertext, and `flake.derivationIndex` as one rollback-capable transaction. A
state-only finalization would produce an undecryptable fleet, so the wrapper
refuses it.

Run the focused check with:

```sh
nix build 'path:.#checks.x86_64-linux.identity-rotation' -L
nix build 'path:.#checks.x86_64-linux.identity-rotation-vm' -L
```

The `path:.` form includes uncommitted scaffold changes while developing them.

## Test fixtures

`fixtures/current.hex` and `fixtures/next.hex` are public, fixed test vectors.
They are not BIP-85 wallet output and must never be used outside the test. The
two-target simulator derives exact SSH, age, and machine-ID vectors for `alpha`
and `beta` only in a temporary directory.

The simulator proves the manifest rules for prepare, partial rollout, rollback,
resume, and finalize, including rejection of skipped and inconsistent states.
The bridge policy also has fixed Nix assertions for current/bridge/next
selection and explicit SSH key-pair tests.

The two-node NixOS VM check uses the same public fixtures with real agenix
activation and OpenSSH. It proves current boot, all-current preparation, partial
rollout, rollback and cancellation, dual-recipient decryption, strict host-key
trust, machine-ID selection, and final promotion of persistent host and age
identities. It models the production lifecycle without reading production roots
or writing production artifacts.

## Rotation scope

This is a routine root-generation rotation, not compromise recovery. The next
root may come from another BIP-85 index on the current mnemonic or any index on
a new mnemonic. The transition keeps the current fleet-global v1 derivation
model. Versioned domain separation and per-host roots remain separate future
work.

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

## Bridge contract

The bridge is inert while `state.json` is idle. An active manifest expects these
next-generation artifacts:

- encrypted next root: `secrets/rotation/next/hex.age`
- passphrase-encrypted next master: `secrets/rotation/next/id_age.age`
- next master recipient: `secrets/rotation/next/id_age.pub`
- host public keys: `hosts/<host>/ssh_host_ed25519_key.pub.next`
- user/service SSH public keys: `users/<name>/id_ed25519.pub.next`
- user age recipients: `users/<name>/id_age.pub.next`
- next master identity at runtime: `/tmp/id_age_next`

Generated `hex-next` ciphertext is deployed only to NixOS targets. Home Manager
targets never receive either fleet root; they use the user age identities that
the NixOS activation prepares side by side.

While the manifest is active:

- every system trusts current and next host and login public keys
- NixOS and Home Manager agenix use both local private identity paths
- host state `current` advertises only the current host key
- host state `bridge` advertises current then next
- host state `next` advertises next then current and selects the next root for
  machine IDs, password salts, and derived runtime credentials
- Home Manager state `next` selects its next age recipient for generated
  ciphertext
- identity state `next` selects the next SSH client, Btrbk, or Beszel identity

Current private material remains available throughout active mode. Returning a
target from `next` through `bridge` to `current` therefore restores current
selection without recreating keys. On finalization, the prepared host private
key is promoted only if it matches the new canonical public key; rollback
instead removes the unused next key.

Preparation must commit the marker, active manifest, next public artifacts, and
generated `hex-next` ciphertext together. Deploy that all-current prepared state
to every target before moving any target to `bridge`.

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

Do not create production index-2 artifacts until these remaining items are
implemented and tested:

- managed creation and rollback-capable finalization of root, master, public,
  and generated ciphertext artifacts; state-only finalization is blocked
- migration checks for machine IDs, Arr, MQTT, Hermes, Camofox, and other
  derived runtime credentials, including required service restarts or reboots
