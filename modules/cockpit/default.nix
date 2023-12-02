# modules.cockpit.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.cockpit;
  secrets = config.age.secrets;

  inherit (lib) mkIf mkOption mkBefore mkForce types;
  inherit (lib.strings) toInt;
  inherit (builtins) toString;

in {

  options.modules.cockpit = {
    enable = lib.options.mkEnableOption "cockpit"; 
    hostName = mkOption {
      type = types.str;
      default = "cockpit.${config.networking.fqdn}";
    };
    port = mkOption {
      type = types.port;
      default = 9090; 
    };
  };

  config = mkIf cfg.enable {

    services.cockpit = {
      enable = true;
      package = pkgs.unstable.cockpit;
      port = cfg.port;
      settings = {
        WebService.Origins = "https://${cfg.hostName}";
      };
    };

    environment.systemPackages = [
      pkgs.nur.repos.dukzcry.cockpit-machines
      pkgs.nur.repos.dukzcry.libvirt-dbus
    ];

    services.udisks2.enable = true;
    services.packagekit.enable = true;

    # Enable database and reverse proxy
    modules.traefik.enable = true;

    # traefik proxy 
    services.traefik.dynamicConfigOptions.http = {
      routers.cockpit = {
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        middlewares = [ "local@file" ];
        service = "cockpit";
      };
      services.cockpit.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString cfg.port}"; }];
    };

  };

}
