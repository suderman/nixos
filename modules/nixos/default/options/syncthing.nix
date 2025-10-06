{
  config,
  lib,
  hostName,
  flake,
  ...
}: let
  inherit (lib) listToAttrs map;
  syncPort = 22000; # tcp/udp
  webguiPort = 8384; # tcp
  discoveryPort = 21027; # udp

  # find all home-manager users with syncthing enabled
  users = flake.lib.filterUsers config (user: user.services.syncthing.enable);
in {
  networking.firewall = let
    # [ 0 1 2 ... ]
    portOffsets = map (user: user.home.portOffset) users;

    # [ 22000 22001 22002 ... ]
    syncPorts = map (portOffset: syncPort + portOffset) portOffsets;

    # [ 8384 8385 8386 ... ]
    webguiPorts = map (portOffset: webguiPort + portOffset) portOffsets;
    # Open firewall for user syncthing service
  in {
    allowedTCPPorts = syncPorts ++ webguiPorts;
    allowedUDPPorts = syncPorts ++ [discoveryPort];
  };

  # Enable reverse proxy { "syncthing-jon" = "http://cog:8384"; }
  services.traefik.proxy = listToAttrs (map (user:
    with user.home; {
      name = "syncthing-${username}";
      value = "http://${hostName}:${toString (webguiPort + portOffset)}";
    })
  users);
}
