# Users with services.wayvnc.enable in Home Manager; see that module.
{
  lib,
  config,
  flake,
  ...
}: let
  users = flake.lib.filterUsers config (user: user.services.wayvnc.enable);
in {
  # wayvnc checks passwords against its own PAM service.
  security.pam.services = lib.mkIf (users != []) {wayvnc = {};};

  # noVNC for each user, from LAN and tailnet only: { "vnc-june" = "http://127.0.0.1:6180"; }
  services.traefik.proxy = lib.listToAttrs (map (user: {
      name = "vnc-${user.home.username}";
      value = "http://127.0.0.1:${toString user.services.wayvnc.webPort}";
    })
    users);
}
