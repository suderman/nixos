{ config, lib, pkgs, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./.;

  xdg.userDirs = with config.home; {
    enable = true;
    createDirectories = false;
    download = "${homeDirectory}/Downloads";
    desktop = "${homeDirectory}/Personal";
    documents = "${homeDirectory}/Personal/Documents";
    music = "${homeDirectory}/Personal/Music";
    pictures = "${homeDirectory}/Personal/Images";
    videos = "${homeDirectory}/Personal/Videos";
    # publicShare = "${homeDirectory}/public";
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 16;
  };
  
  home.packages = with pkgs; [ 
    loupe
  ];


}
