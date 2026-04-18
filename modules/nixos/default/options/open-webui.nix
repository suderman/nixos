# services.open-webui.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.services.open-webui;
in {
  options.services.open-webui = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "open-webui";
      description = "Traefik proxy name for this Open WebUI instance.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.open-webui = {
      isSystemUser = true;
      group = "open-webui";
      home = cfg.stateDir;
    };

    users.groups.open-webui = {};

    tmpfiles.directories = [
      {
        target = cfg.stateDir;
        user = "open-webui";
        group = "open-webui";
        mode = "0750";
      }
    ];

    persist.storage.directories = [cfg.stateDir];

    systemd.services.open-webui.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "open-webui";
      Group = lib.mkForce "open-webui";
      StateDirectory = lib.mkForce null;
    };

    services.traefik.proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
  };
}
