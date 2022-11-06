{ config, pkgs, ... }: 
{
  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    desktop = "${config.home.homeDirectory}/data";
    documents = "${config.home.homeDirectory}/data/documents";
    download = "${config.home.homeDirectory}/tmp";
    music = "${config.home.homeDirectory}/data/music";
    pictures = "${config.home.homeDirectory}/data/images";
    publicShare = "${config.home.homeDirectory}/public";
    videos = "${config.home.homeDirectory}/data/videos";
  };

  # xdg.portal = {
  #   enable = true;
  #   extraPortals = with pkgs; [
  #     xdg-desktop-portal-wlr
  #     xdg-desktop-portal-gtk
  #   ];
  #   gtkUsePortal = true;
  # };

}
