{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [ 

    tdesktop slack
    xorg.xeyes
    jetbrains-mono
    gst_all_1.gst-libav

    _1password-cli _1password-gui 
    junction libreoffice newsflash

    lapce # text editor 
    tauon # music player

    pavucontrol 

    gnome-disk-utility

    asunder # cd ripper

    loupe # png/jpg viewer

    cantarell-fonts

  ];

  programs.bluebubbles.enable = true;
  programs.chromium.enable = true;
  programs.foot.enable = false;
  programs.gimp.enable = true;
  programs.wezterm.enable = false;

  programs.sparrow.enable = true;
  programs.zwift.enable = true;

  programs.obs-studio = with pkgs.unstable; {
    enable = true;
    package = obs-studio;
    # plugins = [ obs-studio-plugins.wlrobs ];
  };

  programs.immich = {
    enable = true;
    url = "https://immich.lux";
  };

  programs.lunasea = {
    enable = true;
    url = "https://lunasea.lux";
  };

  programs.jellyfin = {
    enable = true;
    url = "https://jellyfin.lux";
  };

  programs.home-assistant = {
    enable = true;
    url = "https://hass.hub";
  };

  services.flatpak = {
    enable = true;
    apps = [
      "io.github.dvlv.boxbuddyrs"
      "io.gitlab.zehkira.Monophony"
      "org.emptyflow.ArdorQuery"
      "com.github.treagod.spectator"
    ];
  };

}
