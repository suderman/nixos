# services.home-assistant.mqtt.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.services.home-assistant;
  mqtt = cfg.mqtt;
  inherit (lib) concatMapStringsSep mkEnableOption mkIf mkOption types;
  passwordFileFor = userName: "${mqtt.passwordDir}/${userName}";
in {
  options.services.home-assistant.mqtt = {
    enable = mkEnableOption "MQTT broker for Home Assistant";

    port = mkOption {
      type = types.port;
      default = 1883;
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/mosquitto";
    };

    passwordDir = mkOption {
      type = types.str;
      default = "/run/mosquitto-passwords";
    };

    discoveryPrefix = mkOption {
      type = types.str;
      default = "homeassistant";
    };

    homeAssistantUser = mkOption {
      type = types.str;
      default = "homeassistant";
    };

    deviceUser = mkOption {
      type = types.str;
      default = "mqtt-device";
    };
  };

  config = mkIf (cfg.enable && mqtt.enable) {
    services.mosquitto = {
      enable = true;
      dataDir = mqtt.dataDir;
      listeners = [
        {
          inherit (mqtt) port;
          users = {
            ${mqtt.homeAssistantUser} = {
              passwordFile = passwordFileFor mqtt.homeAssistantUser;
              acl = ["readwrite #"];
            };
            ${mqtt.deviceUser} = {
              passwordFile = passwordFileFor mqtt.deviceUser;
              acl = ["readwrite #"];
            };
          };
        }
      ];
    };

    persist.storage.directories = [mqtt.dataDir];
    networking.firewall.allowedTCPPorts = [mqtt.port];

    system.activationScripts.home-assistant-mqtt-passwords = let
      inherit (perSystem.self) mkScript derive;
      hex = config.age.secrets.hex.path;
      userNames = [
        mqtt.homeAssistantUser
        mqtt.deviceUser
      ];
      writePassword = userName: ''
        derive hex ${lib.escapeShellArg "mqtt:${config.networking.hostName}:${userName}"} 32 <${hex} >"$tmp"
        install -m600 -o root -g root "$tmp" ${lib.escapeShellArg (passwordFileFor userName)}
      '';
      text =
        # bash
        ''
          if [[ -f ${hex} ]]; then
            install -dm700 -o root -g root ${lib.escapeShellArg mqtt.passwordDir}
            tmp="$(mktemp)"

            ${concatMapStringsSep "\n" writePassword userNames}

            rm -f "$tmp"
          fi
        '';
      path = [derive];
    in
      lib.mkAfter ''
        # Derive Mosquitto passwords into /run so they never enter the Nix store.
        ${mkScript {inherit text path;}}
      '';
  };
}
