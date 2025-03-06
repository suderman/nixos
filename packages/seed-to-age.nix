{ perSystem, pkgs, ... }: let

  path = pkgs.lib.makeBinPath [ 
    pkgs.coreutils
    pkgs.ssh-to-age
    perSystem.self.seed-to-ssh
  ];

in pkgs.writeScriptBin "seed-to-age" ''
  #!/usr/bin/env bash
  export PATH=${path}:$PATH

  # Exit if seed missing (standard input)
  seed="$(cat)"
  [[ -z "$seed" ]] && exit 0

  # Use seed-to-age (this flake) to generate ssh key from seed
  ssh="$(echo "$seed" | seed-to-ssh)"
  [[ -z "$ssh" ]] && exit 0

  # Use https://github.com/Mic92/ssh-to-age to generate age from ssh key
  age="$(echo "$ssh" | ssh-to-age -private-key)"
  [[ -z "$age" ]] && exit 0

  # Build formatted identity and output
  echo "# imported from: $(echo "$ssh" | private-to-public)"
  echo "# public key: $(echo "$age" | private-to-public)"
  echo "$age"
''
