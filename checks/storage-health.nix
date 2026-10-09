{pkgs, ...}:
pkgs.runCommand "storage-health-check" {nativeBuildInputs = [pkgs.python3];} ''
  export PYTHONDONTWRITEBYTECODE=1
  python ${../modules/nixos/default/options/storage-health}/test_storage_health.py
  touch "$out"
''
