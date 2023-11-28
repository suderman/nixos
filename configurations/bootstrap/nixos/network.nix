{ config, this, ... }: {

  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------

  networking = {

    # Hostname passed as argument from flake
    hostName = this.host; 
    domain = this.domain;

    # Fewer IP addresses, please
    enableIPv6 = false;

    # Firewall
    firewall.enable = true;

  };

}
