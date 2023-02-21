# services.ydotool.enable = true;
{ config, lib, pkgs, ... }: 

with pkgs; 

let 
  cfg = config.services.ydotool;

in {

  options = {
    services.ydotool.enable = lib.options.mkEnableOption "ydotool"; 
  };

  config = lib.mkIf cfg.enable {

    # Install ydotool package
    environment.systemPackages = [ ydotool ];

    systemd.services.ydotool = {
      description = "starts ydotoold service";
      requires = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      wantedBy = [ "sysinit.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.ydotool}/bin/ydotoold";
        ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        KillMode = "process";
        TimeoutSec = 180;
      };
    };

  };

}


