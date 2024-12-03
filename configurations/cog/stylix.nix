{ config, lib, pkgs, this, inputs, ... }: let 

  inherit (lib) mkAttrs mkIf mkOption types;

in {

  # Import stylix module
  imports = [ inputs.stylix.nixosModules.stylix ];

  config = {

    stylix = {
      enable = true;
      autoEnable = true;
      image = pkgs.fetchurl {
        url = "https://www.pixelstalk.net/wp-content/uploads/2016/05/Epic-Anime-Awesome-Wallpapers.jpg";
        sha256 = "enQo3wqhgf0FEPHj2coOCvo7DuZv+x5rL/WIo4qPI50=";
      };
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      cursor = {
        name = "Banana";
        package = pkgs.banana-cursor;
        size = 36;
      };
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrains Mono";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
        sizes = {
          applications = 11;
          terminal = 12;
          desktop = 11;
          popups = 11;
        };
      };
      opacity = {
        applications = 1.0;
        terminal = 0.95;
        desktop = 1.0;
        popups = 1.0;
      };
      polarity = "dark";
      targets = {
        grub.enable = false;
        gnome.enable = false;
        gtk.enable = true;
        nixos-icons.enable = true;
      };
    };

  };

}
