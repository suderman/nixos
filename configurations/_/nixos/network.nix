{ config, _, ... }: {

  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------

  networking = {

    # Hostname passed as argument from flake
    hostName = _.host; 
    domain = _.domain;

    # Fewer IP addresses, please
    enableIPv6 = false;

    # Firewall
    firewall.enable = true;

  };

}
