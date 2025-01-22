{ config, lib, pkgs, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./.;

  xdg.userDirs = with config.home; {
    enable = true;
    createDirectories = false;
    desktop = "${homeDirectory}/Action";
    download = "${homeDirectory}/Downloads";
    documents = "${homeDirectory}/Documents";
    music = "${homeDirectory}/Music";
    pictures = "${homeDirectory}/Pictures";
    videos = "${homeDirectory}/Videos";
    # publicShare = "${homeDirectory}/public";
  };

  # home.pointerCursor = {
  #   gtk.enable = true;
  #   package = pkgs.adwaita-icon-theme;
  #   name = "Adwaita";
  #   size = 16;
  # };
  
  home.packages = with pkgs; [ 
    loupe
    pkgs.stable.calcure
  ];

  # Enable email/calendars/contacts
  accounts.enable = true;

  # Enable desktop programs
  gui.enable = true;

  stylix.targets = {
    # hyprland.enable = false;
    # rofi.enable = false;
  };

}
