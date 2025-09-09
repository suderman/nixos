{
  config,
  lib,
  ...
}: let
  cfg = config.tmpfiles;
  inherit (lib) mkAfter mkOption types;
in {
  options.tmpfiles = let
    option = mkOption {
      type = with types; listOf (either str attrs);
      default = [];
    };
  in {
    directories = option;
    files = option;
    symlinks = option;
  };
}
