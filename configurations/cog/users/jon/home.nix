{ config, lib, pkgs, this, ... }: let 
  inherit (this.lib) ls;
in {

  # Import all *.nix files in this directory
  imports = ls ./.;

  xdg.userDirs = with config.home; {
    enable = true;
    createDirectories = false;
    download = "${homeDirectory}/tmp";
    desktop = "${homeDirectory}/data";
    documents = "${homeDirectory}/data/documents";
    music = "${homeDirectory}/data/music";
    pictures = "${homeDirectory}/data/images";
    videos = "${homeDirectory}/data/videos";
    # publicShare = "${homeDirectory}/public";
  };

  modules.keyd.enable = true;

  # # TUI bluetooth management
  # modules.bluetuith.enable = true;

  # # Audio visualizer
  # home.packages = with pkgs; [ cava ];
  # xdg.configFile."cava/config".text = ''
  #   [input]
  #   method = pulse
  #   source = auto
  # '';

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.gnome.adwaita-icon-theme;
    name = "Adwaita";
    size = 16;
  };
  
  home.packages = with pkgs; [ 
    loupe
    hyprpicker
    hyprshot
    hyprlock
    hypridle
    hyprnome
    # hyprspace
    hyprpaper
    hyprcursor
  ];


}
