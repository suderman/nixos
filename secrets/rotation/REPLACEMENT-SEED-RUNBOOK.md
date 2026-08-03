# Replacement seed rotation runbook

This runbook rotates the fleet from `derivationIndex = 1` to index `0` derived
from a replacement mnemonic.

The `1 -> 0` transition is supported. `derivationIndex` is recovery metadata,
not a monotonic generation number. Use the index `0` hex derived from the new
mnemonic.

> [!CAUTION]
> If the old seed may be compromised, stop. This availability-first workflow
> deliberately trusts old and new identities together until finalization. It is
> not emergency compromise containment.

## Critical rules

- Do not manually edit `flake.nix`; finalization changes
  `derivationIndex = 1;` to `0`.
- Do not manually create `secrets/rotation/ACTIVE`.
- Enter only the 64-character BIP-85 hex, never the mnemonic.
- Keep the old mnemonic and both master passphrases until the final idle
  generation runs everywhere.
- Do not run `agenix edit`, `agenix rekey`, `agenix import`, or
  `nixos generate` during rotation.
- The software cannot prove that the supplied hex belongs to the new mnemonic.
  Derive index `0` twice and verify it independently.

The expected inventory is 23 targets:

```text
nixos:      cog eve hub kit lux pow sim wit
home:       cog-jon cog-ness eve-jon hub-jon kit-jon
            lux-jon pow-jon sim-jon wit-jon wit-ness
identities: beszel btrbk jon ness root
```

## 1. Preflight

Enter the development shell and confirm the existing idle state:

```sh
nix develop
git status --short
nixos rotation status
```

Expected:

```text
status=idle
currentIndex=1
nextIndex=None
current=23
bridge=0
next=0
preparedHosts=0/8
nextHosts=0/8
```

Run the checks before touching production:

```sh
nix build 'path:.#checks.x86_64-linux.identity-rotation' -L
nix build 'path:.#checks.x86_64-linux.identity-rotation-vm' -L
nix flake check -L
```

Ensure every host is reachable, including `sim`. Commit and push any unrelated
work first.

## 2. Prepare index 0

Run:

```sh
nixos rotation prepare 0
```

The command will:

1. Unlock the current index-1 master.
2. Ask for the new mnemonic's BIP-85 index-0 hex.
3. Derive completely new master, host, user, and service identities.
4. Ask for a passphrase to protect the new master identity.
5. Generate current-compatible and next-compatible ciphertext.
6. Evaluate every host in all-current and all-next configurations.
7. Create `ACTIVE`, activate the transition ledger, and stage the artifacts.

Afterward:

```sh
nixos rotation status
git diff --cached --check
git diff --cached --stat
```

Expected status:

```text
status=active
currentIndex=1
nextIndex=0
current=23
preparedHosts=0/8
```

Review and commit the prepared generation:

```sh
git commit -m "feat(identity): prepare replacement seed generation"
```

Do not commit if preparation leaves `PREPARE.json`; run
`nixos rotation recover` first.

## 3. Deploy the prepared configuration

Deploy the all-current prepared generation to every host, preferably starting
with `sim` and non-critical hosts:

```sh
nixos rotation deploy-prepared sim
nixos rotation deploy-prepared cog
nixos rotation deploy-prepared eve
nixos rotation deploy-prepared hub
nixos rotation deploy-prepared kit
nixos rotation deploy-prepared lux
nixos rotation deploy-prepared pow
nixos rotation deploy-prepared wit
```

Each command switches the host, verifies its exact prepared-artifact token, and
stages the updated `state.json`.

Commit each attestation as recommended by the rotation runbook:

```sh
git commit -m "chore(identity): attest sim prepared"
```

Use the corresponding host name for each commit.

If deployment succeeded but attestation failed, fix the problem and retry only:

```sh
nixos rotation verify-prepared HOST
```

Completion should show:

```text
current=23
preparedHosts=8/8
nextHosts=0/8
```

At this point every host still uses index 1, but has validated index-0 material
available beside it.

## 4. Move everything to bridge

Every target must move through `bridge`; skipping directly to `next` is
rejected.

For each NixOS target:

```sh
nixos rotation move nixos cog bridge
git commit -m "chore(identity): bridge nixos cog"
```

Repeat for all eight NixOS names.

For each Home Manager target:

```sh
nixos rotation move home cog-jon bridge
git commit -m "chore(identity): bridge home cog-jon"
```

Repeat for all ten Home Manager names.

For each identity:

```sh
nixos rotation move identities beszel bridge
git commit -m "chore(identity): bridge identity beszel"
```

Repeat for all five identities.

Status should now show:

```text
current=0
bridge=23
next=0
preparedHosts=8/8
```

Deploy this bridge configuration to every host using ordinary
`nixos-rebuild`. There is deliberately no `deploy-bridge` wrapper:

```sh
nixos-rebuild --target-host HOST --sudo --ask-sudo-password \
  --flake ".#HOST" switch
```

For the local host:

```sh
sudo nixos-rebuild --flake ".#$(hostname)" switch
```

Deploy one host at a time and verify SSH reconnection and important services.
Bridge mode advertises both host-key generations with the current key first.

## 5. Move everything to next

Move the same 23 targets from `bridge` to `next`:

```sh
nixos rotation move nixos cog next
git commit -m "chore(identity): select next nixos cog"

nixos rotation move home cog-jon next
git commit -m "chore(identity): select next home cog-jon"

nixos rotation move identities beszel next
git commit -m "chore(identity): select next identity beszel"
```

Repeat using every target from the inventory.

Do not deploy a next host until all 23 ledger entries are next. `deploy-next`
enforces this.

Expected status:

```text
current=0
bridge=0
next=23
preparedHosts=8/8
nextHosts=0/8
```

Run the focused check and ensure the worktree is clean:

```sh
nix build 'path:.#checks.x86_64-linux.identity-rotation' -L
git status --short
```

## 6. Boot and verify every next host

For remote hosts:

```sh
nixos rotation deploy-next HOST
```

This installs the boot generation, reboots the host, waits for SSH, validates
the new host key, machine ID, derived credentials, and services, then records
the attestation.

Commit each successful attestation:

```sh
git commit -m "chore(identity): attest HOST at replacement seed"
```

`deploy-next` refuses to reboot the machine where it is currently running. For
that local host:

```sh
sudo nixos-rebuild --flake ".#HOST" boot
sudo reboot
```

After returning:

```sh
nix develop
nixos rotation verify-next HOST
git commit -m "chore(identity): attest HOST at replacement seed"
```

Start with `sim`, then less critical hosts, and leave the
administrative/control host until last.

Completion must show:

```text
next=23
preparedHosts=8/8
nextHosts=8/8
```

Do not bypass any failed verifier.

## 7. Finalize

Finalization requires a clean worktree:

```sh
git status --short
nixos rotation status
nix build 'path:.#checks.x86_64-linux.identity-rotation' -L
```

Then run:

```sh
nixos rotation finalize
```

Finalization will:

1. Unlock or recover both master identities.
2. Re-encrypt every source secret exclusively to the new master.
3. Promote all `.next` public artifacts to canonical paths.
4. Change `flake.derivationIndex` from `1` to `0`.
5. Return `state.json` to idle with `currentIndex=0`.
6. Remove transition artifacts and `ACTIVE`.
7. Promote `/tmp/id_age_next` to the current runtime master.
8. Stage the complete finalization.

If `/tmp/id_age_next` disappeared because the control machine rebooted,
finalization decrypts `secrets/rotation/next/id_age.age` and asks for its
passphrase.

The existing devshell still contains the index-1 `nixos` wrapper. Exit and
re-enter it after finalization:

```sh
exit
nix develop
nixos rotation status
```

Expected:

```text
status=idle
currentIndex=0
nextIndex=None
current=23
preparedHosts=0/8
nextHosts=0/8
```

Validate and commit:

```sh
agenix hex --check
git diff --cached --check
nix build 'path:.#checks.x86_64-linux.identity-rotation' -L
nix flake check -L
git commit -m "feat(identity): finalize replacement seed rotation"
```

Do not run `nixos rotation cleanup` after successful finalization; finalization
already removes the next artifacts. `cleanup` is for a cancelled rollback.

## 8. Deploy the final idle generation

Every host is currently booted into the active all-next generation. Deploy the
finalized idle configuration so `.next` identities become canonical and old
fallback keys disappear.

For each remote host:

```sh
nixos-rebuild --target-host HOST --sudo --ask-sudo-password \
  --flake ".#HOST" boot
ssh -t HOST sudo systemctl reboot
```

For the local host:

```sh
sudo nixos-rebuild --flake ".#HOST" boot
sudo reboot
```

Verify SSH and important services after each reboot. When every host runs the
final idle generation:

```sh
nixos rotation status
agenix hex --check
agenix lock
```

Only then retire the old mnemonic and old master passphrase according to the
backup policy.

## Recovery

If preparation or finalization is interrupted, do not manually remove journals
or artifacts:

```sh
nixos rotation recover
git status
nixos rotation status
```

If the rotation must be abandoned before finalization, move every target
backward through `next -> bridge -> current`, run `nixos rotation cancel`,
deploy the reverted current generation everywhere, and then run
`nixos rotation cleanup`.
