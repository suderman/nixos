# services.ocis.enable = true;
{ config, lib, pkgs, ... }: let 

  cfg = config.services.ocis;
  inherit (lib) mkIf options;

in {

  options.services.ocis = {
    enable = options.mkEnableOption "ocis"; 
  };

  config = mkIf cfg.enable {

    # add owncloud and owncloudcmd to path
    home.packages = with pkgs; [ 
      unstable.owncloud-client 
      unstable.qt6.qtwayland 
    ];

    # run at launch
    wayland.windowManager.hyprland.settings = {
      exec-once = [ "owncloud" ];
    };

  };

}
