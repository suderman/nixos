# services.docker-hass.enable = true;
{ config, lib, pkgs, ... }:

let

  inherit (lib) mkIf mkOption mkBefore types strings;
  inherit (lib.options) mkEnableOption;
  inherit (builtins) toString readFile;

  cfg = config.services.docker-hass;
  stateDir = "/var/lib/hass";

in {

  imports = [ 
    ./hass.nix 
    ./zwave.nix 
    ./isy.nix 
  ];

  options = {
    services.docker-hass.enable = mkEnableOption "docker-hass"; 

    services.docker-hass.zigbee = mkOption {
      description = "Path to Zigbee USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0" ];
    };
    services.docker-hass.zwave = mkOption {
      description = "Path to Zwave USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-0658_0200-if00" ];
    };
    # services.docker-hass.insteon = mkOption {
    #   description = "Path to Insteon USB device";
    #   type = types.str;
    #   default = "";
    #   example = [ "/dev/serial/by-id/usb-Prolific_Technology_Inc._USB-Serial_Controller_DVADb116L16-if00-port0" ];
    # };
  };

  config = mkIf cfg.enable {

    # Inspired from services.home-assistant
    users.users.hass = {
      isSystemUser = true;
      group = "hass";
      description = "Home Assistant daemon user";
      home = "${stateDir}";
      uid = config.ids.uids.hass;
    };

    users.groups.hass = {
      gid = config.ids.gids.hass;
    };

  };


}
