# services.flatpak.enable = true;
{ config, pkgs, lib, ... }:

let
  cfg = config.services.flatpak;
  flatpak = "${pkgs.flatpak}/bin/flatpak";

in {

  config = lib.mkIf cfg.enable {

    # systemd.services.flatpak = lib.mkIf cfg.enable {
    #   wantedBy = [ "multi-user.target" ];
    #   # wantedBy = [ "network-online.target" ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     Restart = "on-failure";
    #     RestartSec = "5";
    #   };
    #   script = ''
    #     ${flatpak} remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    #   '';
    # };

  };

}
