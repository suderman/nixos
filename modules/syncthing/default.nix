{ config, lib, this, ... }: let

  inherit (lib) filterUsers listToAttrs map;
  syncPort = 22000; # tcp/udp
  webguiPort = 8384; # tcp
  discoveryPort = 21027; # udp

  # find all home-manager users with syncthing enabled
  users = filterUsers (user: user.services.syncthing.enable) config;
      
in {

  networking.firewall = let

    # [ 0 1 2 ... ]
    offsets = map (user: user.home.offset) users; 

    # [ 22000 22001 22002 ... ]
    syncPorts = map (offset: syncPort + offset) offsets; 

    # [ 8384 8385 8386 ... ]
    webguiPorts = map (offset: webguiPort + offset) offsets; 

  # Open firewall for user syncthing service
  in {
    allowedTCPPorts = syncPorts ++ webguiPorts;  
    allowedUDPPorts = syncPorts ++ [ discoveryPort ];  
  };

  # Enable reverse proxy { "syncthing-jon" = "http://cog:8384"; }
  services.traefik.proxy = listToAttrs( map( user: with user.home; {
    name = "syncthing-${username}";
    value = "http://${hostName}:${toString( webguiPort + offset )}";
  } ) users );

}
