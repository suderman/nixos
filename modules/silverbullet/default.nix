# services.silverbullet.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.services.silverbullet;
  inherit (builtins) toString;
  inherit (lib) mkIf extraGroups;

in {

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.silverbullet = 913;
    ids.gids.silverbullet = 913;

    # Ensure consistent UID/GIDs
    users = {
      users = {

        # Silverbullet user
        silverbullet = {
          home = cfg.spaceDir;
          uid = config.ids.uids.silverbullet;
        };

      # Add admins to the silverbullet group
      } // extraGroups this.admins [ "silverbullet" ];

      # Silverbullet group
      groups.silverbullet = {
        gid = config.ids.gids.silverbullet;
      };

    };

    # Ensure data directory exists
    file."${cfg.spaceDir}" = {
      type = "dir"; mode = 775; 
      user = config.users.users.silverbullet.uid; 
      group = config.users.groups.silverbullet.gid;
    };


    # Enable reverse proxy
    services.silverbullet.listenPort = 3003;
    services.traefik = {
      enable = true;
      proxy.silverbullet = "http://${cfg.listenAddress}:${toString cfg.listenPort}";
    };

  };

}
