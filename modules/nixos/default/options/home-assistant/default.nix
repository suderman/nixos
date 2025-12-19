# -- custom module --
# services.home-assistant.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.services.home-assistant;
  inherit (lib) mkIf mkOption options types;
  inherit (flake.lib) extraGroups ls sudoers;

  # https://github.com/home-assistant/core/pkgs/container/home-assistant/versions?filters%5Bversion_type%5D=tagged
  version = "2025.12.4";

  # https://github.com/zwave-js/zwave-js-ui/pkgs/container/zwave-js-ui/versions?filters%5Bversion_type%5D=tagged
  zwaveVersion = "11.9.0";
in {
  imports = ls ./.;
  disabledModules = ["services/home-automation/home-assistant.nix"];

  options.services.home-assistant = {
    enable = options.mkEnableOption "home-assistant";

    version = mkOption {
      type = types.str;
      default = version;
    };

    name = mkOption {
      type = types.str;
      default = "home-assistant";
    };

    ip = mkOption {
      type = types.str;
      default = "127.0.0.1"; # IP address for the Home Assistant instance
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/hass"; # Data directory for the Home Assistant instance
    };

    zigbee = mkOption {
      type = types.str;
      default = ""; # Path to Zigbee USB device
      example = ["/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0"];
    };

    zwave = mkOption {
      type = types.str;
      default = ""; # Path to Z-Wave USB device
      example = ["usb-Nabu_Casa_ZWA-2_80B54EE1C718-if00"];
    };

    zwaveName = mkOption {
      type = types.str;
      default = "zwave";
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

    isyName = mkOption {
      type = types.str;
      default = "isy";
    };
  };

  config = mkIf cfg.enable {
    # Inspired from services.home-assistant
    users = {
      users =
        {
          # Create user
          hass = {
            isSystemUser = true;
            group = "hass";
            description = "Home Assistant daemon user";
            home = "${cfg.dataDir}";
            uid = config.ids.uids.hass;
          };
        }
        # Add sudoers to the immich group
        // extraGroups (sudoers flake.users) ["hass"];

      # Create group
      groups.hass = {
        gid = config.ids.gids.hass;
      };
    };

    # Ensure data directory exists
    tmpfiles.directories = let
      dir = {
        mode = 775;
        user = config.users.users.hass.uid;
        group = config.users.groups.hass.gid;
      };
    in [
      (dir // {target = "${cfg.dataDir}";})
      (dir // {target = "${cfg.dataDir}/.cloud";})
      (dir // {target = "${cfg.dataDir}/.storage";})
      (dir // {target = "${cfg.dataDir}/blueprints";})
      (dir // {target = "${cfg.dataDir}/deps";})
      (dir // {target = "${cfg.dataDir}/tts";})
      (dir // {target = "${cfg.dataDir}/zwave";})
    ];

    persist.storage.directories = [cfg.dataDir];

    # Postgres database configuration
    # This "hass" postgres user isn't actually being used to access the database.
    # Since the docker is running the container as root, the "root" postgres user
    # is what needs access, but that account already has access to all databases.
    services.postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "hass";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = ["hass"];
    };

    # Init service
    systemd.services.home-assistant = let
      service = config.systemd.services.home-assistant;
    in {
      enable = true;
      description = "Initiate home assistant services";
      wantedBy = ["multi-user.target"];
      after = ["postgresql.service"]; # run this after db
      before = [
        # run this before the rest:
        "docker-home-assistant.service"
        "docker-zwave.service"
      ];
      wants = service.after ++ service.before;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      path = with pkgs; [docker];
      script = with config.virtualisation.oci-containers.containers;
        ''
          docker pull ${home-assistant.image};
        ''
        + (
          if cfg.zwave == ""
          then ""
          else ''
            docker pull ${zwave.image};
          ''
        );
    };
  };
}
