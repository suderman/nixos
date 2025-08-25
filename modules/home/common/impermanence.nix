{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.impermanence.persist = {
    # Files relative to ~/ home
    files = mkOption {
      description = "Home files to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = [".bashrc"];
    };

    # Directories relative to ~/ home
    directories = mkOption {
      description = "Home directories to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = ["Documents"];
    };
  };

  options.impermanence.scratch = {
    # Files relative to ~/ home
    files = mkOption {
      description = "Home files to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = [".bashrc"];
    };

    # Directories relative to ~/ home
    directories = mkOption {
      description = "Home directories to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = ["Documents"];
    };
  };
}
