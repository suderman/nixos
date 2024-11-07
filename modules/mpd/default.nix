{ config, lib, ... }: let

  inherit (lib) attrValues filterAttrs hasAttr map;
  mdpPort = 6600; # default port for mpd control
  httpPort = 8600; # default port for http streaming

in {

  # Check for home-manager (not-root) configurations
  networking.firewall = if ! hasAttr "home-manager" config then {} else {

    # Open firewall for user mpd service
    allowedTCPPorts = let  

      # find all home-manager users with mpd enabled
      users = filterAttrs( _: user: (user.services.mpd.enable == true) ) config.home-manager.users; 

      # [ 0 1 2 ... ]
      offsets = map (user: user.home.offset) (attrValues users); 

      # [ 6600 6601 6602 ... ]
      mdpPorts = map (offset: mdpPort + offset) offsets; 

      # [ 8600 8601 8602 ... ]
      httpPorts = map (offset: httpPort + offset) offsets; 

    in mdpPorts ++ httpPorts;

  };

}
