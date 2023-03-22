# base.enable = true;
{ config, lib, host, domain, ... }: with lib; {

  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------
  config = mkIf config.base.enable {

    networking = {

      # Hostname passed as argument from flake
      hostName = host; 
      domain = domain;

      # Fewer IP addresses, please
      enableIPv6 = false;

      # Firewall
      firewall.enable = true;

    };

  };

}
