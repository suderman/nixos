{ config, lib, this, ... }:

let

  cfg = config.this;
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
  
  # Define this options
  options.this = mkOption { 
    type = types.attrs; 
    default = this // {

      # Persist state with Impermanence module";
      stateDir = "/nix/state";

      # Persist files in relative to / root
      files = [];

      # Persist directories relative to / root
      dirs = [];

    }; 
  };

  # Create new users.user option to store user name defined in this
  options.users.user = mkOption { type = types.str; default = this.user; };

  # ---------------------------------------------------------------------------
  # Common Configuration for all NixOS systems
  # ---------------------------------------------------------------------------
  # Get all modules settings from configuration's default.nix
  config = (optionalAttrs (this ? config) (recursiveUpdate this.config {})) // {

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
