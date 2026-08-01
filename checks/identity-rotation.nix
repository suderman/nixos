{
  flake,
  pkgs,
  perSystem,
  ...
}: let
  fixtureState = status: targetState: {
    schema = 1;
    inherit status;
    currentIndex = 1;
    nextIndex =
      if status == "active"
      then 2
      else null;
    targets = {
      home."alpha-jon" = targetState;
      identities.jon = targetState;
      nixos.alpha = targetState;
    };
  };
  current = flake.lib.identityRotationFor (fixtureState "idle" "current");
  bridge = flake.lib.identityRotationFor (fixtureState "active" "bridge");
  next = flake.lib.identityRotationFor (fixtureState "active" "next");
in
  assert !current.active;
  assert current.keyFiles ["key"] == ["key"];
  assert bridge.keyFiles ["key"] == ["key" "key.next"];
  assert bridge.select "nixos" "alpha" "old" "new" == "old";
  assert next.select "nixos" "alpha" "old" "new" == "new";
  assert next.useNext "identities" "jon";
    pkgs.runCommand "identity-rotation-check" {
      nativeBuildInputs = [
        pkgs.python3
        perSystem.self.derive
      ];
      DERIVATION_INDEX = toString flake.derivationIndex;
      DERIVE_BIN = "${perSystem.self.derive}/bin/derive";
      REPOSITORY = ../.;
    } ''
      export PYTHONPYCACHEPREFIX="$TMPDIR/pycache"
      python3 -m py_compile "$REPOSITORY/secrets/rotation/identity_rotation.py"
      python3 "$REPOSITORY/secrets/rotation/identity_rotation.py" validate \
        "$REPOSITORY/secrets/rotation/state.json" \
        --repository "$REPOSITORY" \
        --derivation-index "$DERIVATION_INDEX"
      python3 "$REPOSITORY/secrets/rotation/test.py"
      touch "$out"
    ''
