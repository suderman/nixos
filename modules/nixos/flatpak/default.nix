# services.flatpak.enable = true;
{ config, pkgs, lib, ... }:

let
  cfg = config.services.flatpak;

in {

  config = lib.mkIf cfg.enable {

    systemd.services.flatpak = lib.mkIf cfg.enable {
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
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  };

}
