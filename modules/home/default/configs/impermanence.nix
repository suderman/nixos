{
  config,
  osConfig,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options.persist = {
    storage.path = mkOption {
      description = "Path to storage directory";
      type = types.str;
      default = "${osConfig.persist.storage.path}/${config.home.homeDirectory}";
    };

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

    scratch.path = mkOption {
      description = "Path to scratch directory";
      type = types.str;
      default = "${osConfig.persist.scratch.path}/${config.home.homeDirectory}";
    };

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
