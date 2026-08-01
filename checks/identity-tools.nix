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
    perSystem.self.nixos
    perSystem.self.sshed
  ];
  DERIVE_BIN = "${perSystem.self.derive}/bin/derive";
  AGENIX_SCRIPT = ../packages/agenix/agenix.sh;
  NIXOS_SCRIPT = ../packages/nixos/nixos.sh;
  SSHED_BIN = "${perSystem.self.sshed}/bin/sshed";
  BASH_BIN = "${pkgs.bash}/bin/bash";
  REAL_MV = "${pkgs.coreutils}/bin/mv";
} ''
  bash -n ${../packages/agenix/agenix.sh}
  bash -n ${../packages/derive/derive.sh}
  bash -n ${../packages/nixos/nixos.sh}
  bash -n ${../packages/sshed/sshed.sh}
  PYTHONPYCACHEPREFIX="$TMPDIR/pycache" python3 -m py_compile ${../packages/derive/hex.py}
  bash ${../packages/derive/test.sh}
  bash ${../packages/agenix/test.sh}
  bash ${../packages/nixos/test.sh}
  bash ${../packages/sshed/test.sh}
  PRJ_ROOT=${../.} ${perSystem.self.nixos}/bin/nixos rotation status |
    grep -q 'status=idle currentIndex=1 nextIndex=None'
  touch "$out"
''
