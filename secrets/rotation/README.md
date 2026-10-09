# Identity rotation state

`state.json` records the fleet-wide rotation phase that `nixos rotation`
manages: `idle`, `prepare`, or `switch`. During a rotation it also holds the
next derivation index, and `next/hex.age` holds the next root encrypted to the
current master.

Change these files only with `nixos rotation`. The process, safety checks, and
rollback are in the [seed rotation runbook](../../docs/seed-rotation.org).
