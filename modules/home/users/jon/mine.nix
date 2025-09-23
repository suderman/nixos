{
  config,
  pkgs,
  perSystem,
  ...
}: let
  inherit (perSystem.self) mkScript;
  inherit (config.networking) hostName;

  xmrigd = mkScript {
    name = "xmrigd";
    inputs = [pkgs.xmrig];
    # source ${config.age.secrets.btc-env.path}
    text = ''
      export MINER_USER="BTC:''${MINER_ADD}.${hostName}#''${MINER_REF}"
      xmrig --url=rx.unmineable.com:3333 --algo=rx --keepalive --user="''${MINER_USER}" --pass=x --cpu-max-threads-hint="''${1:-100}"
    '';
  };
in {
  home.packages = with pkgs; [
    xmrig
    xmrigd
  ];
}
