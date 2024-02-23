# modules.unifi.enable = true;
{ config, lib, pkgs, this, ... }:

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

    name = mkOption {
      type = types.str;
      default = "unifi";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/unifi";
    };

    gateway = mkOption {
      type = types.str;
      default = ""; # IP address for the gateway
    };

    gatewayName = mkOption {
      type = types.str;
      default = "rt";
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

    # Ensure data directory exists
    file."${cfg.dataDir}" = {
      type = "dir"; mode = 775; 
      user = config.users.users.unifi.uid; 
      group = config.users.groups.unifi.gid;
    };

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
      path = with pkgs; [ docker ];
      script = with config.virtualisation.oci-containers.containers; ''
        docker pull ${unifi.image};
      '';
    };


  };

}
