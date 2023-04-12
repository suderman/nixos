# modules.unifi.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.unifi;
  inherit (lib) mkIf mkOption options types strings;
  inherit (builtins) toString;

in {

  imports = [ 
    ./unifi.nix 
    ./gateway.nix 
  ];

  options.modules.unifi = {

    enable = options.mkEnableOption "unifi"; 

    hostName = mkOption {
      type = types.str;
      default = "unifi.${config.networking.fqdn}";
      description = "FQDN for the Unifi Controller instance";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/unifi";
      description = "Data directory the Unifi Controller instance";
    };

  };

  config = mkIf cfg.enable {

    # Used to be set in nixpkgs, restoring here
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.unifi = 183;
    ids.gids.unifi = 183;

    # Inspired from services.unifi
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/unifi.nix
    users.users.unifi = {
      isSystemUser = true;
      group = "unifi";
      description = "UniFi controller daemon user";
      home = "${cfg.dataDir}";
      uid = config.ids.uids.unifi;
    };

    users.groups.unifi = {
      gid = config.ids.gids.unifi;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Init service
    systemd.services.unifi = {
      enable = true;
      description = "Initiate Unifi service";
      wantedBy = [ "multi-user.target" ];
      wants = [ "docker-unifi.service" ]; 
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      script = let
        uid = toString config.users.users.unifi.uid;
        gid = toString config.users.groups.unifi.gid;
      in ''
        mkdir -p ${cfg.dataDir}
        chown -R ${uid}:${gid} ${cfg.dataDir}
      '';
    };

  };

}
