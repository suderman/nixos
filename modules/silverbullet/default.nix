# modules.silverbullet.enable = true;
{ config, lib, pkgs, ... }:

let

  # https://github.com/silverbulletmd/silverbullet/releases
  version = "0.5.3";

  cfg = config.modules.silverbullet;
  ownership = with config.ids; "${toString uids.silverbullet}:${toString gids.silverbullet}";

  inherit (config.users) user;
  inherit (lib) mkIf mkOption options types strings mkBefore;
  inherit (builtins) toString;

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

    users.users.silverbullet = {
      isSystemUser = true;
      group = "silverbullet";
      description = "silverbullet daemon user";
      home = cfg.dataDir;
      uid = config.ids.uids.silverbullet;
    };

    users.groups.silverbullet = {
      gid = config.ids.gids.silverbullet;
    };

    # Add user to the silverbullet group
    users.users."${user}".extraGroups = [ "silverbullet" ]; 

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.silverbullet = {
      image = "zefhemel/silverbullet:${version}";
      autoStart = true;

      # Run as silverbullet user
      user = ownership;

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

      preStart = mkBefore ''
        mkdir -p ${cfg.dataDir}
        chown -R ${ownership} ${cfg.dataDir}
      '';

      # traefik should be running before this service starts
      after = [ "traefik.service" ];

      # If the proxy goes down, take down this service too
      requires = [ "traefik.service" ];

    };

  };

}
