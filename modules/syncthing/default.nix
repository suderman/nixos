{ config, lib, this, ... }: let

  inherit (lib) attrValues filter filterUsers map mkAttrs removePrefix;
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
  services.traefik.proxy = mkAttrs 
    ( map( user: "syncthing-${user.home.username}" ) users ) 
    ( subdomain: let 
        user = removePrefix "syncthing-" subdomain;
        inherit (config.home-manager.users."${user}".home) offset;
      in "http://${this.hostName}:${toString( webguiPort + offset )}" );

}
