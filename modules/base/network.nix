{ config, base, ... }: {

  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------

  networking = {

    # Hostname passed as argument from flake
    hostName = base.host; 
    domain = base.domain;

    # Fewer IP addresses, please
    enableIPv6 = false;

    # Firewall
    firewall.enable = true;

  };

}
