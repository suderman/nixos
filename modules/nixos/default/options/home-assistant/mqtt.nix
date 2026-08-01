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
  passwordDir = "/run/mosquitto-passwords";
  homeAssistantUser = "homeassistant";
  deviceUser = "mqtt-device";
  passwordFileFor = userName: "${passwordDir}/${userName}";
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
  };

  config = mkIf (cfg.enable && mqtt.enable) {
    identityRotation.verificationCommands =
      concatMapStringsSep "\n" (userName: ''
        verify_derived ${lib.escapeShellArg "mqtt:${config.networking.hostName}:${userName}"} ${lib.escapeShellArg (passwordFileFor userName)} 32
      '') [homeAssistantUser deviceUser]
      + ''
        systemctl is-active --quiet mosquitto.service
      '';
    identityRotation.verificationUnits = ["mosquitto.service"];

    services.mosquitto = {
      enable = true;
      dataDir = mqtt.dataDir;
      listeners = [
        {
          inherit (mqtt) port;
          # Separate credentials avoid sharing Home Assistant's password with devices.
          users = {
            ${homeAssistantUser} = {
              passwordFile = passwordFileFor homeAssistantUser;
              acl = ["readwrite #"];
            };
            ${deviceUser} = {
              passwordFile = passwordFileFor deviceUser;
              acl = ["readwrite #"];
            };
          };
        }
      ];
    };

    systemd.services.mosquitto.restartTriggers = [config.identityRotation.hexPath];

    persist.storage.directories = [mqtt.dataDir];
    networking.firewall.allowedTCPPorts = [mqtt.port];

    system.activationScripts.home-assistant-mqtt-passwords = let
      inherit (perSystem.self) mkScript derive;
      hex = config.identityRotation.hexPath;
      userNames = [
        homeAssistantUser
        deviceUser
      ];
      writePassword = userName: ''
        derive hex ${lib.escapeShellArg "mqtt:${config.networking.hostName}:${userName}"} 32 <${hex} >"$tmp"
        install -m600 -o root -g root "$tmp" ${lib.escapeShellArg (passwordFileFor userName)}
      '';
      text =
        # bash
        ''
          if [[ -f ${hex} ]]; then
            install -dm700 -o root -g root ${lib.escapeShellArg passwordDir}
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
