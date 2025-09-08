{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.persist = {
    # Files relative to ~/ home
    storage.files = mkOption {
      description = "Home files to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = [".bashrc"];
    };

    # Directories relative to ~/ home
    storage.directories = mkOption {
      description = "Home directories to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = ["Documents"];
    };
  };

  options.persist = {
    # Files relative to ~/ home
    scratch.files = mkOption {
      description = "Home files to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = [".bashrc"];
    };

    # Directories relative to ~/ home
    scratch.directories = mkOption {
      description = "Home directories to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = ["Documents"];
    };
  };
}
