{ pkgs, ... }: let

  path = pkgs.lib.makeBinPath [ 
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.openssh
    pkgs.rage
  ];

in pkgs.writeScriptBin "private-to-public" ''
  #!/usr/bin/env bash
  export PATH=${path}:$PATH

  # Exit if private key missing (standard input)
  key="$(cat)"
  [[ -z "$key" ]] && exit 0

  # If age identity detected, extract recipient from secret and output
  if [[ ! -z "$(echo "$key" | grep "AGE-SECRET-KEY")" ]]; then
    echo "$key" | rage-keygen -y

  # If ssh ed25519 detected, extract public key from secret and output
  elif [[ ! -z "$(echo "$key" | grep "OPENSSH PRIVATE KEY")" ]]; then
    ssh-keygen -y -f <(echo "$key") | cut -d ' ' -f 1,2

  # Fallback on echoing the input to output
  else
    echo "$key"
  fi
''
