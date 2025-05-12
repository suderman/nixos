{ lib, hostName, ... }: let
  inherit (lib) mkDefault;
in {

  # Derive hostName from blueprint ./hosts/dir
  networking.hostName = hostName;

  # Set your time zone.
  time.timeZone = mkDefault "America/Edmonton";

}
