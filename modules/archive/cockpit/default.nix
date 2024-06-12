# modules.cockpit.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.cockpit;

  inherit (lib) mkIf mkOption mkBefore mkForce types;
  inherit (lib.strings) toInt;
  inherit (builtins) toString;
  inherit (config.age) secrets;

in {

  options.modules.cockpit = {
    enable = lib.options.mkEnableOption "cockpit"; 
    name = mkOption {
      type = types.str;
      default = "cockpit";
    };
    port = mkOption {
      type = types.port;
      default = 9999; # default port is 9090
    };
  };

  config = mkIf cfg.enable {

    services.cockpit = {
      enable = true;
      package = pkgs.unstable.cockpit;
      port = cfg.port;
      settings = {
        WebService.Origins = "https://${cfg.name}.${this.hostName}";
      };
    };

    environment.systemPackages = [
      # pkgs.nur.repos.dukzcry.cockpit-machines
      # pkgs.nur.repos.dukzcry.libvirt-dbus
    ];

    services.udisks2.enable = true;
    services.packagekit.enable = true;

    modules.traefik = {
      enable = true;
      routers.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
