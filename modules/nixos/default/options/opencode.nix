{
  config,
  lib,
  flake,
  ...
}: let
  # find all home-manager users with opencode program enabled
  users = flake.lib.filterUsers config (user: user.programs.opencode.enable);
in {
  # Enable reverse proxy for each user { "opencode-jon" = "http://127.0.0.1:4090"; }
  services.traefik.proxy = lib.listToAttrs (map (user:
    with user.programs.opencode; {
      inherit name;
      value = "http://127.0.0.1:${toString port}";
    })
  users);
}
