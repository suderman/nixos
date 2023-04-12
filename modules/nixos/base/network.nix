{ config, lib, host, domain, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf;

in {

  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------
  config = mkIf cfg.enable {

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
