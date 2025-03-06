{ perSystem, pkgs, ... }: let
  path = pkgs.lib.makeBinPath [ 
    pkgs.zbar
    perSystem.self.seed-to-age 
  ];
in pkgs.writeScriptBin "qr-to-age" ''
  #!/usr/bin/env bash
  export PATH=${path}:$PATH
  zbarcam --raw --oneshot | seed-to-age
''
