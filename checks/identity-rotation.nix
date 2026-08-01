{
  flake,
  pkgs,
  perSystem,
  ...
}:
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
