{ config, pkgs, lib, ... }: 

let
  inherit (config) xdg;
  inherit (lib) mkIf;

  # homeage secrets combined with age files paths
  homeage = config.homeage // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };

in {
  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    # desktop = "${config.home.homeDirectory}/data";
    # documents = "${config.home.homeDirectory}/data/documents";
    # download = "${config.home.homeDirectory}/tmp";
    # music = "${config.home.homeDirectory}/data/music";
    # pictures = "${config.home.homeDirectory}/data/images";
    # publicShare = "${config.home.homeDirectory}/public";
    # videos = "${config.home.homeDirectory}/data/videos";
  };

  # xdg.portal = {
  #   enable = true;
  #   extraPortals = with pkgs; [
  #     xdg-desktop-portal-wlr
  #     xdg-desktop-portal-gtk
  #   ];
  #   gtkUsePortal = true;
  # };

  # agenix
  homeage.file = mkIf homeage.enable {
    super-secret.source = homeage.files.self-env;
    super-secret.symlinks = [ "${xdg.configHome}/super-secret.txt" "${xdg.configHome}/super-duper-secret.txt" ];
  };

}
