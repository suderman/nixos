# services.silverbullet.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.services.silverbullet;
  inherit (builtins) toString;
  inherit (lib) extraGroups mkIf mkOption toOwnership types;
  inherit (config.age) secrets;

in {

  options.services.silverbullet = {
    ocisHostName = mkOption {
      type = types.str;
      default = "";
      example = "ocis.example.com";
    };
    ocisDir = mkOption {
      type = types.str;
      default = "/";
      example = "Notes";
    };
  };

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

    systemd = ( if cfg.ocisHostName == "" then {} else { 

      # Bidirectional sync of space dir with OCIS webdav
      services = let 
        serviceConfig = {
          Type = "oneshot";
          EnvironmentFile = [ secrets.ocis-env.path ]; # WEBDAV_USER, WEBDAV_PASS
        };
        path = [ pkgs.rclone ];
        script = ''
          export RCLONE_CONFIG_OCIS_URL=https://${cfg.ocisHostName}/remote.php/webdav
          export RCLONE_CONFIG_OCIS_TYPE=webdav
          export RCLONE_CONFIG_OCIS_VENDOR=owncloud
          export RCLONE_CONFIG_OCIS_USER=$WEBDAV_USER
          export RCLONE_CONFIG_OCIS_PASS=$(rclone obscure $WEBDAV_PASS)
          export FLAGS="$RESYNC --create-empty-src-dirs --compare size --slow-hash-sync-only --resilient --fix-case"
          rclone --no-check-certificate bisync $FLAGS ${cfg.spaceDir} ocis:${cfg.ocisDir}
          chown -R ${toOwnership config.users.users.silverbullet.uid config.users.groups.silverbullet.gid} ${cfg.spaceDir}
        '';
      in { 

        "silverbullet-sync-init" = {
          wantedBy = [ "multi-user.target" ];
          after = [ "silverbullet.service" ];
          environment.RESYNC = "--resync";
          inherit serviceConfig path script;
        };

        "silverbullet-sync" = {
          environment.RESYNC = "";
          inherit serviceConfig path script;
        };

      };

      # Run this script every time a file modification is detected in the directory
      paths."silverbullet-sync" = {
        wantedBy = [ "multi-user.target" ];
        partOf = [ "silverbullet-sync.service" ];
        pathConfig = { 
          PathChanged = cfg.spaceDir; 
          Unit = "silverbullet-sync.service";
        };
      };

      # Run this script every 5 minutes
      timers."silverbullet-sync" = {
        wantedBy = [ "timers.target" ];
        partOf = [ "silverbullet-sync.service" ];
        timerConfig = {
          OnCalendar = "*:0/5";
          Unit = "silverbullet-sync.service";
        };
      };

    } );

  };
}
