{ config, pkgs, lib, username, ... }:

let
  cfg = config.services.flatpak;
  flatpak = "${pkgs.flatpak}/bin/flatpak";

in {

  # services.flatpak.enable = true;
  systemd.services.flatpak = lib.mkIf cfg.enable {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${flatpak} remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

}
