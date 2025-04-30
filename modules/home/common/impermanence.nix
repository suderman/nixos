{ config, lib, ... }: let
  inherit (lib) mkAfter mkOption types;
in {

  options.persist = {

    # Files relative to ~/ home
    files = mkOption {
      description = "Home files to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ ".bashrc" ];
    };

    localFiles = mkOption {
      description = "Home files to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ ".bashrc" ];
    };

    # Directories relative to ~/ home
    directories = mkOption {
      description = "Home directories to persist reboots and snapshot";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "Documents" ];
    };

    # Directories relative to ~/ home
    localDirectories = mkOption {
      description = "Home directories to persist reboots";
      type = with types; listOf (either str attrs);
      default = [];
      example = [ "Documents" ];
    };

  };

}
