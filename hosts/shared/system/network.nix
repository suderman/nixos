{ config, lib, pkgs, host, domain, ... }: {

  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------

  # Hostname passed as argument from flake
  networking.hostName = host; 
  networking.domain = domain;

  # Fewer IP addresses, please
  networking.enableIPv6 = false;

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPortRanges = [
      { from = 4000; to = 4007; }
      { from = 8000; to = 8010; }
    ];
  };

}
