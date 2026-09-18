# stylix.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.stylix;
  inherit (lib) mkDefault;
  inherit (config.lib.stylix) pixel;
in {
  # Import stylix module
  imports = [flake.inputs.stylix.nixosModules.stylix];

  # Keep the previous choice available during the Commit Mono trial.
  config.fonts.packages = [pkgs.ioskeley-mono.normal];

  # Upstream 1.143 gives its italic faces a separate primary family, which
  # makes Kitty synthesize regular text instead of selecting the italic files.
  config.fonts.fontconfig.localConf = ''
    <match target="scan">
      <test name="family" compare="eq">
        <string>CommitMonoV143</string>
      </test>
      <edit name="family" mode="assign_replace">
        <string>CommitMono</string>
      </edit>
    </match>
  '';

  config.stylix = {
    enable = mkDefault true;
    autoEnable = mkDefault cfg.enable;
    polarity = mkDefault "dark"; # dark light either

    image = mkDefault (pixel "base00");
    base16Scheme = mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    # base16Scheme = mkDefault "${pkgs.base16-schemes}/share/themes/tokyo-city-dark.yaml";

    opacity = {
      applications = mkDefault 1.0;
      terminal = mkDefault 0.85;
      desktop = mkDefault 1.0;
      popups = mkDefault 1.0;
    };

    icons = {
      enable = true;

      # package = pkgs.reversal-icon-theme;
      # light = "Reversal";
      # dark = "Reversal";

      # package = pkgs.papirus-icon-theme;
      # light = "Papirus-Light";
      # dark = "Papirus-Dark";

      package = mkDefault pkgs.qogir-icon-theme;
      light = mkDefault "Qogir-Light";
      dark = mkDefault "Qogir-Dark";
    };

    cursor = {
      # name = "macOS";
      # package = pkgs.apple-cursor;
      name = mkDefault "Banana";
      package = mkDefault pkgs.banana-cursor;
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
        package = pkgs.commit-mono;
        name = "CommitMono";
      };

      sansSerif = mkDefault {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      serif = mkDefault {
        package = pkgs.literata;
        name = "Literata";
      };

      emoji = mkDefault {
        package = pkgs.noto-fonts-color-emoji;
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
      gtksourceview.enable = false; # Home Manager installs the theme without rebuilding dependents.
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
