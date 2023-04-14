# modules.lunasea.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.lunasea;
  inherit (lib) mkIf mkOption options types strings;
  inherit (builtins) toString;

in {

  imports = [ 
    ./sabnzbd.nix 
  ];

  options.modules.lunasea = {

    enable = options.mkEnableOption "lunasea"; 

    hostName = mkOption {
      type = types.str;
      default = "lunasea.${config.networking.fqdn}";
      description = "FQDN for the LunaSea instance";
    };

    # dataDir = mkOption {
    #   type = types.path;
    #   default = "/var/lib/unifi";
    #   description = "Data directory the Unifi Controller instance";
    # };

  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # # Init service
    # systemd.services.lunasea = {
    #   enable = true;
    #   description = "Initiate LunaSea service";
    #   wantedBy = [ "multi-user.target" ];
    #   wants = [ "docker-lunasea.service" ]; 
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = "yes";
    #   };
    #   script = let
    #     uid = toString config.users.users.unifi.uid;
    #     gid = toString config.users.groups.unifi.gid;
    #   in ''
    #     mkdir -p ${cfg.dataDir}
    #     chown -R ${uid}:${gid} ${cfg.dataDir}
    #   '';
    # };

  };

}
