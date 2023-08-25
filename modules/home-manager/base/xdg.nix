{ config, lib, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf;

  # homeage secrets combined with age files paths
  homeage = config.homeage // { 
    files = config.modules.secrets.files; 
    enable = config.modules.secrets.enable; 
  };

in {

  config = mkIf cfg.enable {

    # # secrets
    # homeage.file = lib.mkIf homeage.enable {
    #   super-secret.source = homeage.files.self-env;
    #   super-secret.symlinks = with config.xdg [ 
    #     "${configHome}/super-secret.txt" 
    #     "${configHome}/super-duper-secret.txt" 
    #   ];
    # };

    xdg.userDirs = {
      enable = true;
      createDirectories = false;
      download = "${config.home.homeDirectory}/tmp";
      desktop = "${config.home.homeDirectory}/data";
      documents = "${config.home.homeDirectory}/data/documents";
      music = "${config.home.homeDirectory}/data/music";
      pictures = "${config.home.homeDirectory}/data/images";
      videos = "${config.home.homeDirectory}/data/videos";
      # publicShare = "${config.home.homeDirectory}/public";
    };

    # xdg.portal = {
    #   enable = true;
    #   extraPortals = with pkgs; [
    #     xdg-desktop-portal-wlr
    #     xdg-desktop-portal-gtk
    #   ];
    #   gtkUsePortal = true;
    # };

  };

}
