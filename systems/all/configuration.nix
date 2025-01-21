{ config, lib, this, ... }:

let

  inherit (lib) optionalAttrs recursiveUpdate;
  inherit (this.lib) ls;

in {

  # Import all *.nix files in this directory
  imports = ls ./.;

  # ---------------------------------------------------------------------------
  # Common Configuration for all NixOS systems
  # (configurations/default.nix auto imports all .nix files in this directory)
  # ---------------------------------------------------------------------------
  # Inherit any config settings in configuration's default.nix
  config = optionalAttrs (this ? config) (recursiveUpdate this.config {

    # Set your time zone.
    time.timeZone = "America/Edmonton";

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.11"; # Did you read the comment?

  });

}
