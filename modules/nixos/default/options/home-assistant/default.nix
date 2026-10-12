# -- custom module --
# services.home-assistant.enable = true;
{
  config,
  lib,
  flake,
  ...
}: let
  cfg = config.services.home-assistant;
  inherit (lib) mkIf mkOption options types;
  inherit (flake.lib) extraGroups ls sudoers;
in {
  imports = ls ./.;
  disabledModules = ["services/home-automation/home-assistant.nix"];

  options.services.home-assistant = {
    enable = options.mkEnableOption "home-assistant";

    version = mkOption {
      type = types.str;
      default = flake.inputs.pins.default.containers.home-assistant.version;
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
      example = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_DCB4D90E3668-if00";
    };

    zwave = mkOption {
      type = types.str;
      default = ""; # Path to Z-Wave USB device
      example = "/dev/serial/by-id/usb-Nabu_Casa_ZWA-2_80B54EE1C718-if00";
    };

    zwaveName = mkOption {
      type = types.str;
      default = "zwave";
    };

    zwaveVersion = mkOption {
      type = types.str;
      default = flake.inputs.pins.default.containers.zwave-js-ui.version;
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
        # Add sudoers to the hass group
        // extraGroups (sudoers flake.users) ["hass"];

      # Create group
      groups.hass = {
        gid = config.ids.gids.hass;
      };
    };

    # Ensure data directory exists, closed to users outside the hass group
    tmpfiles.directories = let
      dir = {
        mode = 770;
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
    # The container runs as root, so map that OS user to the "hass" role for
    # the hass database only. configuration.yaml connects as hass.
    services.postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "hass";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = ["hass"];
      identMap = ''
        hass root hass
      '';
      authentication = ''
        local hass hass peer map=hass
      '';
    };
  };
}
