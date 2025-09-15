{pkgs, ...}: {
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

  # programs.home-assistant = {
  #   enable = true;
  #   url = "https://hass.hub";
  # };

  services.flatpak.apps = [
    "io.github.dvlv.boxbuddyrs"
    "org.emptyflow.ArdorQuery"
    "com.github.treagod.spectator"
  ];

  programs.chromium.enable = true;
  programs.foot.enable = false;
  programs.wezterm.enable = false;
  programs.onepassword.enable = true;
}
