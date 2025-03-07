{ perSystem, pkgs, ... }: let

  path = pkgs.lib.makeBinPath [ 
    pkgs.coreutils
    pkgs.ssh-to-age
    perSystem.self.to-public
    perSystem.self.to-ssh
  ];

in pkgs.writeScriptBin "to-age" ''
  #!/usr/bin/env bash
  export PATH=${path}:$PATH

  # Exit if standard input is missing
  input="$(cat)"
  [[ -z "$input" ]] && exit 0

  # Use to-ssh (this flake) to generate ssh key from input
  ssh="$(echo "$input" | to-ssh)"
  [[ -z "$ssh" ]] && exit 0

  # Use https://github.com/Mic92/ssh-to-age to generate age from ssh key
  age="$(echo "$ssh" | ssh-to-age -private-key)"
  [[ -z "$age" ]] && exit 0

  # Use to-public (this flake) to generate formatted identity and output
  echo "# imported from: $(echo "$ssh" | to-public)"
  echo "# public key: $(echo "$age" | to-public)"
  echo "$age"
''
