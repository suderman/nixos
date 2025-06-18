{ config, pkgs, flake, ... }: {

  home.packages = with pkgs; [ 
    tauon # music player
  ];

  # programs.lunasea = {
  #   enable = true;
  #   url = "https://lunasea.lux";
  # };

  # programs.jellyfin = {
  #   enable = true;
  #   url = "https://jellyfin.lux";
  # };

  services.flatpak.apps = [ "io.gitlab.zehkira.Monophony" ];

}
