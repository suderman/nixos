{ flake, config, lib, hostName, ... }: let
  inherit (lib) mkDefault mkOption types;
in {

  # Extra options for each host
  options = {

    # Servers are stable, desktops can be unstable
    stable = mkOption {
      description = "Follow nixpkgs stable if true, unstable if false";
      type = types.bool;
      default = true;
      example = false;
    };

  };

  config = {

    # Default to x86 linux
    nixpkgs.hostPlatform = mkDefault "x86_64-linux";

    # Set your time zone.
    time.timeZone = mkDefault "America/Edmonton";

    # Derive hostName from blueprint ./hosts/dir
    networking.hostName = hostName;

  };

}
