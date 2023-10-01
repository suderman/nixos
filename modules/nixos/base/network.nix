{ config, lib, base, ... }:

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
      hostName = base.host; 
      domain = base.domain;

      # Fewer IP addresses, please
      enableIPv6 = false;

      # Firewall
      firewall.enable = true;

    };

  };

}
