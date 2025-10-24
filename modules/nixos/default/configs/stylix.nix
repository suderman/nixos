# stylix.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.stylix;
  inherit (lib) mkDefault mkIf;
  inherit (config.lib.stylix) pixel;
in {
  # Import stylix module
  imports = [flake.inputs.stylix.nixosModules.stylix];

  config.stylix = {
    enable = mkDefault true;
    autoEnable = mkDefault cfg.enable;
    polarity = mkDefault "either"; # dark light either

    image = mkDefault (pixel "base00");
    base16Scheme = mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    # base16Scheme = mkDefault "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";

    opacity = {
      applications = mkDefault 1.0;
      terminal = mkDefault 0.85;
      desktop = mkDefault 1.0;
      popups = mkDefault 1.0;
    };

    # cursor = mkDefault {
    #   name = "macOS";
    #   package = pkgs.apple-cursor;
    #   size = 36;
    # };
    cursor = mkDefault {
      name = "Banana";
      package = pkgs.banana-cursor;
      size = mkDefault 36;
    };

    fonts = {
      sizes = {
        applications = mkDefault 11;
        terminal = mkDefault 12;
        desktop = mkDefault 11;
        popups = mkDefault 11;
      };

      monospace = mkDefault {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono";
      };

      sansSerif = mkDefault {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      serif = mkDefault {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      emoji = mkDefault {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };

    targets = {
      # chromium.enable = false;
      # console.enable = false;
      # feh.enable = false;
      # fish.enable = false;
      # gnome.enable = false;
      # grub.enable = false;
      # gtk.enable = false;
      # kmscon.enable = false;
      # lightdm.enable = false;
      # nixos-icons.enable = false;
      # nixvim.enable = false;
      # plymouth.enable = false;
      # regreet.enable = false;
      # spicetify.enable = false;
    };
  };
}
