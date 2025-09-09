{
  config,
  pkgs,
  flake,
  ...
}: {
  home.packages = with pkgs; [
    asunder # cd ripper
    gnome-disk-utility # format and partition gui
    junction # browser chooser
    loupe # png/jpg viewer
    pavucontrol # audio control panel
    xorg.xeyes # test for x11
  ];

  programs.onepassword.enable = true;

  # programs.home-assistant = {
  #   enable = true;
  #   url = "https://hass.hub";
  # };

  services.flatpak.apps = [
    "io.github.dvlv.boxbuddyrs"
    "org.emptyflow.ArdorQuery"
    "com.github.treagod.spectator"
  ];
}
