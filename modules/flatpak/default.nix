# modules.flatpak.enable = true;
{ config, pkgs, lib, ... }:

let

  cfg = config.modules.flatpak;
  inherit (lib) mkIf;

in {

  options.modules.flatpak = {
    enable = lib.options.mkEnableOption "flatpak"; 
  };

  config = mkIf cfg.enable {

    services.flatpak.enable = true;

    systemd.services.flatpak = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "5";
      };
      path = with pkgs; [ iputils flatpak ];
      script = builtins.readFile ./flatpak.sh;
    };

    xdg.portal.enable = true;

  };

}
