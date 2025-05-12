{ flake, config, lib, hostName, ... }: let
  inherit (builtins) attrNames attrValues filter;
  inherit (lib) filterAttrs hasPrefix mkDefault mkOption naturalSort types unique;
in {

  # Extra options for each host
  options.networking = {

    hostNames = mkOption {
      description = "All hostnames this host can be reached at";
      type = with types; listOf str;
      default = [];
    };

    address = mkOption {
      description = "Primary IP address this host can be reached at";
      type = with types; str;
      default = "127.0.0.1";
    };

    addresses = mkOption {
      description = "All IP addresses this host can be reached at";
      type = with types; listOf str;
      default = [];
    };

  };

  config.networking = {

    # Derive primary hostName from blueprint ./hosts/dir
    hostName = hostName;

    # All the hostNames this host can be reached with
    hostNames = filter 
      (name: hasPrefix hostName name) 
      (attrNames flake.networking.records);

    # Primary IP address from flake's zones
    address = flake.networking.records.${hostName} or "127.0.0.1";  

    # All the IP addresses this host can be reached with
    addresses = [ "127.0.0.1" ] ++ unique( naturalSort( attrValues( 
      filterAttrs (name: ip: hasPrefix hostName name) flake.networking.records 
    )));

  };

  # Set your time zone
  config.time.timeZone = mkDefault "America/Edmonton";

}
