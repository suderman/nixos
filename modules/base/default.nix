{ config, lib, base, ... }:

let

  cfg = config.modules.base;
  inherit (lib) mkIf mkOption optionalAttrs recursiveUpdate types;

in {

  imports = [ 
    ./network.nix 
    ./nix.nix 
    ./packages.nix 
    ./root.nix 
    ./security.nix 
    ./state.nix
    ./user.nix 
  ];

  options.modules.base = {
    config = mkOption { type = types.attrs; default = base; };
  };

  # ---------------------------------------------------------------------------
  # Common Configuration for all NixOS hosts
  # ---------------------------------------------------------------------------
  config = {

    # Get all modules settings from configuration's default.nix
    modules = optionalAttrs (base ? modules) (recursiveUpdate base.modules {});

    # Set your time zone.
    time.timeZone = "America/Edmonton";

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.11"; # Did you read the comment?

  };

}
