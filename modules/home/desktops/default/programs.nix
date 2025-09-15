{
  lib,
  pkgs,
  ...
}: {
  programs = {
    chromium.enable = true;
    onepassword.enable = true;

    # services on hub
    home-assistant = {
      url = lib.mkDefault "https://hass.hub";
      enable = lib.mkDefault true;
    };
    isy.enable = lib.mkDefault true;
    # services on lux
    jellyfin = {
      url = lib.mkDefault "https://jellyfin.lux";
      enable = lib.mkDefault true;
    };
    # immich = {
    #   url = lib.mkDefault "https://immich.lux";
    #   enable = lib.mkDefault true;
    # };
    # lunasea = {
    #   url = lib.mkDefault "https://lunasea.lux";
    #   enable = lib.mkDefault true;
    # };

    # Work webapps
    gmail.enable = lib.mkDefault true;
    google-calendar.enable = lib.mkDefault true;
    google-meet.enable = lib.mkDefault true;
    google-analytics.enable = lib.mkDefault true;
    harvest.enable = lib.mkDefault true;
    asana.enable = lib.mkDefault true;
  };

  # TODO: remove or convert to modules
  services.flatpak.apps = [
    "io.github.dvlv.boxbuddyrs"
    "org.emptyflow.ArdorQuery"
    "com.github.treagod.spectator"
  ];

  home.packages = with pkgs; [
    asunder # cd ripper
    gnome-disk-utility # format and partition gui
    junction # browser chooser
    loupe # png/jpg viewer
    pavucontrol # audio control panel
    xorg.xeyes # test for x11
    lapce # text editor
    libreoffice # office suite (writing, spreadsheets, etc)
    newsflash # rss reader
  ];
}
