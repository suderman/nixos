{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options = {
    test = mkOption {
      type = types.anything;
      default = {};
    };
  };
  config = {};
}
