{ config, lib, pkgs, ... }: let 

  inherit (lib) mkShellScript;
  inherit (config.home) hostName;

  xmrigd = mkShellScript { 
    name = "xmrigd"; 
    inputs = [ pkgs.xmrig ];
    text = ''
      source ${config.age.secrets.btc-env.path}
      export MINER_USER="BTC:''${MINER_ADD}.${hostName}#''${MINER_REF}"
      xmrig --url=rx.unmineable.com:3333 --algo=rx --keepalive --user="''${MINER_USER}" --pass=x --cpu-max-threads-hint="''${1:-100}"
    '';
  };

in {

  age.secrets = {
    btc-env.file = config.secrets.files."btc-env";
  };

  home.packages = with pkgs; [ 
    xmrig
    xmrigd
  ];

}
