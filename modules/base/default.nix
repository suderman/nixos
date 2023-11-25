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

  # Define base options
  options.modules.base = {

    # Store copy of base config for reference
    config = mkOption { type = types.attrs; default = base; };

    # Persist in /nix/state
    stateDir = mkOption {
      description = "Persist state with Impermanence module";
      type = types.str;
      default = "/nix/state";
    };

    # Persist files in relative to / root
    files = mkOption {
      description = "System files to preserve";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/machine-id" ];
    };

    # Persist directories relative to / root
    dirs = mkOption {
      description = "System directories to preserve";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "/etc/nixos" ];
    };

  };

  # Create new users.user option to store user name defined in base
  options.users.user = mkOption { type = types.str; default = base.user; };

  # ---------------------------------------------------------------------------
  # Common Configuration for all NixOS systems
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
