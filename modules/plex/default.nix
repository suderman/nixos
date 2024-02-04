# modules.plex.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.plex;
  inherit (lib) mkIf mkOption types;
  inherit (this.lib) extraGroups;

in {

  options.modules.plex = {
    enable = lib.options.mkEnableOption "plex"; 
    name = mkOption {
      type = types.str;
      default = "plex";
    };
    port = mkOption {
      type = types.port;
      default = 32400; 
    };
  };

  config = mkIf cfg.enable {

    services.plex = {
      enable = true;
      user = "plex"; # default
      group = "plex"; # default
      extraPlugins = [];
      extraScanners = [];
      openFirewall = true;
      package = pkgs.plex;
    };

    modules.traefik = { 
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

    # https://www.plex.tv/claim/
    # sudo plex-claim-server claim-xxxxxxxxxxxxxxxxxxxx
    environment.systemPackages = [
      ( pkgs.writeShellScriptBin "plex-claim-server" (builtins.readFile ./plex-claim-server.sh) )
    ];

    # Add admins to the plex group
    users.users = extraGroups this.admins [ "plex" ];

  };

}
