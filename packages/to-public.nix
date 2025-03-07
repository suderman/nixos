# Convenience script to extract public keys from ssh or age identities
{ pkgs, ... }: let

  path = pkgs.lib.makeBinPath [ 
    pkgs.gnugrep
    pkgs.openssh
    pkgs.rage
  ];

in pkgs.writeScriptBin "to-public" ''
  #!/usr/bin/env bash
  export PATH=${path}:$PATH

  # Exit if standard input is missing
  input="$(cat)"
  [[ -z "$input" ]] && exit 0

  # If age identity detected, extract recipient from secret and output
  if [[ ! -z "$(echo "$input" | grep "AGE-SECRET-KEY")" ]]; then
    echo "$input" | rage-keygen -y

  # If ssh ed25519 detected, extract public key from secret and output
  elif [[ ! -z "$(echo "$input" | grep "OPENSSH PRIVATE KEY")" ]]; then
    ssh-keygen -y -f <(echo "$input") | cut -d ' ' -f 1,2

  # Fallback on echoing the input to output
  else
    echo "$input"
  fi
''
