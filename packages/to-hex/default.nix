# Python script for deterministic hex generation
{ pkgs, ... }: pkgs.writeScriptBin "to-hex" ''
  #!/usr/bin/env bash
  exec ${pkgs.python3}/bin/python3 ${./to-hex.py} "$@"
''
