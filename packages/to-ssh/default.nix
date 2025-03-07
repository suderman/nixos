# Input (converted into 32-bytes) used to generate ED25519 key
{ pkgs, ... }: let

  # Python with required packages
  pythonWithPackages = pkgs.python3.withPackages (ps: [
    ps.cryptography
  ]);

# Create wrapper script
in pkgs.writeScriptBin "to-ssh" ''
  #!/usr/bin/env bash
  exec ${pythonWithPackages}/bin/python3 ${./to-ssh.py}
''
