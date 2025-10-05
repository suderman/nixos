{
  lib,
  pkgs,
  ...
}: {
  # manage ~/.config/mimeapps.list.
  xdg.mimeApps.enable = true;
  xdg.mime.enable = true;

  programs = {
    kitty.enable = true; # terminal
    chromium.enable = true; # browser
    firefox.enable = true; # alt browser

    # Home Automation
    home-assistant = {
      enable = true;
      url = lib.mkDefault "https://hass.hub";
    };
    isy.enable = true;
  };

  # TODO: remove or convert to modules
  services.flatpak.apps = [
    "io.github.dvlv.boxbuddyrs"
    "org.emptyflow.ArdorQuery"
    "com.github.treagod.spectator"
  ];

  home.packages = with pkgs; [
    gnome-disk-utility # format and partition gui
    xorg.xeyes # test for x11
    ripdrag # drag + drop files from/to the terminal
  ];
}
