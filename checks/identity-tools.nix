{
  pkgs,
  perSystem,
  ...
}:
pkgs.runCommand "identity-tools-check" {
  nativeBuildInputs = [
    pkgs.bash
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.python3
    perSystem.self.derive
  ];
  DERIVE_BIN = "${perSystem.self.derive}/bin/derive";
  AGENIX_SCRIPT = ../packages/agenix/agenix.sh;
  BASH_BIN = "${pkgs.bash}/bin/bash";
  REAL_MV = "${pkgs.coreutils}/bin/mv";
} ''
  bash -n ${../packages/agenix/agenix.sh}
  bash -n ${../packages/derive/derive.sh}
  PYTHONPYCACHEPREFIX="$TMPDIR/pycache" python3 -m py_compile ${../packages/derive/hex.py}
  bash ${../packages/derive/test.sh}
  bash ${../packages/agenix/test.sh}
  touch "$out"
''
