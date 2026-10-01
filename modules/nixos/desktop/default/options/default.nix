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
      description = "Whether to expose the Stylix palette pair for user-session appearance switching.";
    };

    darkScheme = lib.mkOption {
      type = lib.types.anything;
      default = config.stylix.base16Scheme;
      description = "Dark Stylix scheme exported to desktop themes and Emacs.";
    };

    lightScheme = lib.mkOption {
      type = lib.types.anything;
      default = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
      description = "Light Stylix scheme exported to desktop themes and Emacs.";
    };
  };
}
