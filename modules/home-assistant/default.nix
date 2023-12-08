# modules.home-assistant.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.home-assistant;
  inherit (lib) mkIf mkOption mkBefore options types strings;
  inherit (builtins) toString readFile;
  inherit (this.lib) extraGroups;

  # https://github.com/home-assistant/core/pkgs/container/home-assistant/versions?filters%5Bversion_type%5D=tagged
  version = "2023.11.3";

  # https://github.com/zwave-js/zwave-js-ui/pkgs/container/zwave-js-ui/versions?filters%5Bversion_type%5D=tagged
  zwaveVersion = "9.5.1";

in {

  imports = [ 
    ./hass.nix 
    ./zwave.nix 
    ./isy.nix 
  ];

  options.modules.home-assistant = {

    enable = options.mkEnableOption "home-assistant"; 

    version = mkOption {
      type = types.str;
      default = version;
      description = "Version of the Home Asssistant instance";
    };

    hostName = mkOption {
      type = types.str;
      default = "hass.${config.networking.fqdn}";
      description = "FQDN for the Home Assistant instance";
    };

    ip = mkOption {
      type = types.str;
      default = "192.168.1.4";
      description = "IP address for the Home Assistant instance";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/hass";
      description = "Data directory for the Home Assistant instance";
    };

    zigbee = mkOption {
      description = "Path to Zigbee USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0" ];
    };

    zwave = mkOption {
      description = "Path to Z-Wave USB device";
      type = types.str;
      default = "";
      example = [ "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_3e535b346625ed11904d6ac2f9a97352-if00-port0" ];
    };

    zwaveHostName = mkOption {
      type = types.str;
      default = "zwave.${config.networking.fqdn}";
      description = "FQDN for the Z-Wave UI instance";
    };

    zwaveVersion = mkOption {
      type = types.str;
      default = zwaveVersion;
      description = "Version of the Z-Wave instance";
    };

    isy = mkOption {
      type = types.str;
      default = "";
      description = "IP address for the ISY device";
    };

    isyHostName = mkOption {
      type = types.str;
      default = "isy.${config.networking.fqdn}";
      description = "FQDN for the ISY device";
    };


  };

  config = mkIf cfg.enable {

    # Inspired from services.home-assistant
    users = {
      users = {

        # Create user
        hass = {
          isSystemUser = true;
          group = "hass";
          description = "Home Assistant daemon user";
          home = "${cfg.dataDir}";
          uid = config.ids.uids.hass;
        };

      # Add admins to the hass group
      } // extraGroups this.admins [ "hass" ];

      # Create group
      groups.hass = {
        gid = config.ids.gids.hass;
      };

    };

    # Enable database and reverse proxy
    modules.postgresql.enable = true;
    modules.traefik.enable = true;

    # Postgres database configuration
    # This "hass" postgres user isn't actually being used to access the database.
    # Since the docker is running the container as root, the "root" postgres user
    # is what needs access, but that account already has access to all databases.
    services.postgresql = {
      ensureUsers = [{
        name = "hass";
        ensurePermissions = { "DATABASE hass" = "ALL PRIVILEGES"; };
      }];
      ensureDatabases = [ "hass" ];
    };

    # Init service
    systemd.services.home-assistant = let this = config.systemd.services.home-assistant; in {
      enable = true;
      description = "Initiate home assistant services";
      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" ]; # run this after db
      before = [ # run this before the rest:
        "docker-home-assistant.service"
        "docker-zwave.service"
      ];
      wants = this.after ++ this.before; 
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      script = "mkdir -p ${cfg.dataDir}";
    };

  };


}
