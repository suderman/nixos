# modules.silverbullet.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://github.com/silverbulletmd/silverbullet/releases
  version = "0.5.10";

  cfg = config.modules.silverbullet;

  inherit (lib) mkIf mkOption options types strings mkBefore;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;


in {

  options.modules.silverbullet = {

    enable = options.mkEnableOption "silverbullet"; 

    hostName = mkOption {
      type = types.str;
      default = "silverbullet.${config.networking.fqdn}";
      description = "FQDN for the SilverBullet instance";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/silverbullet";
    };

  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.silverbullet = 913;
    ids.gids.silverbullet = 913;

    users = {
      users = {

        # Add user to the silverbullet group
        silverbullet = {
          isSystemUser = true;
          group = "silverbullet";
          description = "silverbullet daemon user";
          home = cfg.dataDir;
          uid = config.ids.uids.silverbullet;
        };

      # Add admins to the silverbullet group
      } // extraGroups this.admins [ "silverbullet" ];

      # Create group
      groups.silverbullet = {
        gid = config.ids.gids.silverbullet;
      };

    };

    # Ensure data directory exists
    file."${cfg.dataDir}" = {
      type = "dir"; mode = 775; 
      user = config.users.users.silverbullet.uid; 
      group = config.users.groups.silverbullet.gid;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.silverbullet = {
      image = "zefhemel/silverbullet:${version}";
      autoStart = true;

      # Run as silverbullet user
      user = with config.ids; "${toString uids.silverbullet}:${toString gids.silverbullet}";

      # Traefik labels
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.silverbullet.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.silverbullet.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.silverbullet.middlewares=local@file"
      ];

      volumes = [ "${cfg.dataDir}:/space" ];

    };

    # Extend systemd service
    systemd.services.docker-silverbullet = {
      after = [ "traefik.service" ];
      requires = [ "traefik.service" ];
      preStart = with config.virtualisation.oci-containers.containers; ''
        docker pull ${silverbullet.image};
      '';
    };

  };

}
