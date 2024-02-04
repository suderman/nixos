# modules.jellyfin.enable = true;
{ config, lib, pkgs, this, ... }:


let

  cfg = config.modules.jellyfin;
  port = "8096"; 
  inherit (lib) mkIf mkOption types;

in {

  options.modules.jellyfin = {

    enable = lib.options.mkEnableOption "jellyfin"; 

    name = mkOption {
      type = types.str;
      default = "jellyfin";
    };

  };

  config = lib.mkIf cfg.enable {

    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      group = "jellyfin";
      openFirewall = true;
    };

    users.groups.media.members = [ config.services.jellyfin.user ];

    modules.traefik = { 
      enable = true;
      routers."${cfg.name}" = "http://127.0.0.1:${port}";
    };

  };

}
