# services.hass.enable = true;
{ config, lib, pkgs, user, ... }:

let

  cfg = config.services.hass;

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString readFile;

in {

  imports = [ 
    ./hass.nix 
    ./zwave.nix 
    ./isy.nix 
  ];

  options = {
    services.hass.enable = mkEnableOption "hass"; 

    services.hass.host = mkOption {
      type = types.str;
      default = "hass.${config.networking.fqdn}";
      description = "Host for Home Assistant";
    };

    services.hass.ip = mkOption {
      type = types.str;
      default = "192.168.1.4";
      description = "IP address for Home Assistant";
    };

    services.hass.dataDir = mkOption {
      type = types.path;
      default = "/var/lib/hass";
      description = "Data directory for Home Assistant";
    };

    services.hass.zigbee = mkOption {
      description = "Path to Zigbee USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0" ];
    };

    services.hass.zwave = mkOption {
      description = "Path to Z-Wave USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_3e535b346625ed11904d6ac2f9a97352-if00-port0" ];
    };

    services.hass.zwaveHost = mkOption {
      type = types.str;
      default = "zwave.${config.networking.fqdn}";
      description = "Host for Z-Wave";
    };

    services.hass.isy = mkOption {
      type = types.str;
      default = "";
      description = "IP address for ISY";
    };

    services.hass.isyHost = mkOption {
      type = types.str;
      default = "isy.${config.networking.fqdn}";
      description = "Host for ISY";
    };


  };

  config = mkIf cfg.enable {

    # Inspired from services.home-assistant
    users.users.hass = {
      isSystemUser = true;
      group = "hass";
      description = "Home Assistant daemon user";
      home = "${cfg.dataDir}";
      uid = config.ids.uids.hass;
    };

    users.groups.hass = {
      gid = config.ids.gids.hass;
    };

    # Add user to the hass group
    users.users."${user}".extraGroups = [ "hass" ]; 

  };


}
