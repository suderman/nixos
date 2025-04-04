{ flake, config, lib, hostName, ... }: let
  inherit (lib) mkDefault mkOption types;
in {

  # Extra options for each host
  options.networking = {

    addresses = mkOption {
      description = "IP addresses associated with this host";
      type = with types; listOf str;
      default = [];
    };
    
    hostNames = mkOption {
      description = "Hostnames associated with this host";
      type = with types; listOf str;
      default = [];
    };

  };

  config = {

    # Derive hostName from blueprint ./hosts/dir
    networking.hostName = hostName;

  };

}
