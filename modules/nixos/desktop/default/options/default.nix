{
  config,
  flake,
  lib,
  pkgs,
  ...
}: {
  imports = flake.lib.ls ./.;

  options.programs."stylix-theme-toggle" = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.stylix.enable;
      description = "Whether to install a passwordless Stylix dark/light toggle for desktop hosts.";
    };

    lightScheme = lib.mkOption {
      type = lib.types.anything;
      default = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
      description = "Stylix base16 scheme used by the light specialisation.";
    };
  };
}
