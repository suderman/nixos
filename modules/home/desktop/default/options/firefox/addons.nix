{
  lib,
  perSystem,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (perSystem.suderpkgs) easy-container-shortcuts;
in {
  options.programs.firefox = {
    extraAddons = mkOption {
      type = types.anything;
      default = {};
    };
  };

  # To get details, install via firefox and check this URL:
  # about:debugging#/runtime/this-firefox
  config.programs.firefox.extraAddons = {
    inherit easy-container-shortcuts;
  };
}
