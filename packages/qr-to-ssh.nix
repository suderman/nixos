{ perSystem, pkgs, ... }: let
  path = pkgs.lib.makeBinPath [ 
    pkgs.zbar
    perSystem.self.seed-to-ssh 
  ];
in pkgs.writeScriptBin "qr-to-ssh" ''
  #!/usr/bin/env bash
  export PATH=${path}:$PATH
  zbarcam --raw --oneshot | seed-to-ssh
''
