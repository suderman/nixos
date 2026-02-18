{
  config,
  lib,
  ...
}: let
  cfg = config.services.traefik;
  inherit (config.networking) hostName;
  port = 21000;
  users = builtins.attrValues config.home-manager.users;
in {
  config = lib.mkIf cfg.enable {
    services.traefik = {
      extraInternalHostNames = map (user: "${user.home.username}.${hostName}") users;

      dynamicConfigOptions.http = {
        services = lib.listToAttrs (map (user:
          with user.home; {
            name = "user-${username}";
            value.loadBalancer.servers = [
              {
                url = "http://127.0.0.1:${toString (port + portOffset)}";
              }
            ];
          })
        users);
        routers = lib.listToAttrs (map (user:
          with user.home; {
            name = "user-${username}";
            value = {
              entrypoints = "websecure";
              tls = true;
              rule = "HostRegexp(`^[^.]+\\.${username}\\.${hostName}$`)";
              service = "user-${username}";
            };
          })
        users);
      };
    };
  };
}
