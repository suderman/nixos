# services.tiddlywiki.enable = true;
{
  config,
  lib,
  flake,
  ...
}: let
  cfg = config.services.tiddlywiki;
  inherit (lib) mkIf mkOption types;
in {
  options.services.tiddlywiki = {
    name = mkOption {
      type = types.str;
      default = "tiddlywiki";
    };
    port = mkOption {
      default = 3456;
      type = types.port;
    };
  };

  config = mkIf cfg.enable {
    # Add admins to the tiddlywiki group
    users.users = flake.lib.extraGroups (flake.lib.sudoers flake.users) ["tiddlywiki"];

    services.tiddlywiki = {
      listenOptions = {
        port = cfg.port;
        # credentials = "../credentials.csv";
        # readers="(authenticated)";
      };
    };

    # Persist data
    persist.storage.directories = ["/var/lib/private/tiddlywiki"];

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };
  };
}
