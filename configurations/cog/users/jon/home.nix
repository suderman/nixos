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

  # # TUI bluetooth management
  # modules.bluetuith.enable = true;

  # # Audio visualizer
  # home.packages = with pkgs; [ cava ];
  # xdg.configFile."cava/config".text = ''
  #   [input]
  #   method = pulse
  #   source = auto
  # '';

}
