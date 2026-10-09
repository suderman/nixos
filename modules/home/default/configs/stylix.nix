# osConfig.stylix.enable = true;
{
  config,
  osConfig,
  lib,
  ...
}: let
  cfg = config.stylix;
  oscfg = osConfig.stylix;
  inherit (lib) mkIf mkDefault mkForce;
in {
  config = {
    stylix = mkIf oscfg.enable {
      # Enable with nixos module
      enable = mkDefault true;
      autoEnable = mkDefault oscfg.enable;

      # Targets: https://nix-community.github.io/stylix/options/platforms/home_manager.html
      targets = {
        firefox.profileNames = ["default"];
        gtk.extraCss = ''
          menubar,
          menubar > menuitem,
          menu,
          .menu {
            background-color: @window_bg_color;
            background-image: none;
            color: @window_fg_color;
          }

          menubar > menuitem:hover,
          menubar > menuitem:focus,
          menubar > menuitem:active,
          menubar > menuitem:selected,
          menu > menuitem:hover,
          menu > menuitem:focus,
          menu > menuitem:active,
          menu > menuitem:selected,
          menuitem:hover,
          menuitem:focus,
          menuitem:active,
          menuitem:selected {
            background-color: @headerbar_bg_color;
            background-image: none;
            color: @window_fg_color;
          }
        '';
        hyprpaper.enable = mkForce false; # don't set my wallpaper
      };
    };

    # Home Manager 26.05 no longer defaults GTK4 to the GTK3 theme.
    gtk.gtk4.theme = mkDefault null;
  };
}
