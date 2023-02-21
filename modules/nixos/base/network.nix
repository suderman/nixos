# base.enable = true;
{ config, lib, host, domain, publicDomain, ... }: with lib; {

  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------
  options.networking.publicDomain = mkOption { type = types.str; };

  config = mkIf config.base.enable {

    networking = {

      # Hostname passed as argument from flake
      hostName = host; 
      domain = domain;
      publicDomain = publicDomain;

      # Fewer IP addresses, please
      enableIPv6 = false;

      # Firewall
      firewall = {
        enable = true;
        # allowedTCPPorts = [ 80 443 ];
        # allowedUDPPortRanges = [
        #   { from = 4000; to = 4007; }
        #   { from = 8000; to = 8010; }
        # ];
      };

    };

  };

}
