{
  lib,
  pkgs,
  ...
}: {
  programs = {
    zathura.enable = true; # pdf reader
    mpv.enable = true; # media player
    imv.enable = true; # image viewer
    freetube.enable = true; # youtube client

    # Photo Library
    immich = {
      enable = true;
      url = lib.mkDefault "https://immich.lux";
    };
    # Media Library
    jellyfin = {
      enable = true;
      url = lib.mkDefault "https://jellyfin.lux";
    };
  };

  home.packages = with pkgs; [
    pulseaudio # pactl
    pavucontrol # sound control gui
    ncpamixer # sound control tui
    tauon # music player
    asunder # cd ripper
    newsflash # rss reader
  ];

  services.flatpak.apps = ["io.gitlab.zehkira.Monophony"];

  # Remember audio settings
  persist.storage.directories = [".local/state/wireplumber"];
}
