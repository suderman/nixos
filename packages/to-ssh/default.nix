# Python script for deterministic key generation
{ pkgs, ... }: let

  # Python with required packages
  pythonWithPackages = pkgs.python3.withPackages (ps: [
    ps.cryptography
  ]);

# Create wrapper script
in pkgs.writeScriptBin "seed-to-ssh" ''
  #!/usr/bin/env bash
  exec ${pythonWithPackages}/bin/python3 ${./to-ssh.py}
''
