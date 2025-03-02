{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [ 
    _1password-cli _1password-gui # password manager
    asunder # cd ripper
    gnome-disk-utility # format and partition gui
    junction # browser chooser 
    lapce # text editor 
    libreoffice  # office suite (writing, spreadsheets, etc)
    loupe # png/jpg viewer
    newsflash # rss reader
    pavucontrol # audio control panel
    slack # Slack chatroom
    tauon # music player
    tdesktop # Telegram messenger
    xorg.xeyes # test for x11
  ];

  programs.bluebubbles.enable = true;
  programs.chromium.enable = true;
  programs.foot.enable = false;
  programs.wezterm.enable = false;
  programs.sparrow.enable = true;
  programs.zwift.enable = true;

  programs.obs-studio = with pkgs.unstable; {
    enable = true;
    package = obs-studio;
    plugins = with obs-studio-plugins; [
      obs-pipewire-audio-capture
    ];
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
