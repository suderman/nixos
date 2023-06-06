# modules.hyprland.enable = true;
{ config, pkgs, lib, inputs, ... }: 

let 

  cfg = config.modules.hyprland;
  inherit (lib) mkIf;

in {

  # Import hyprland module
  imports = [ inputs.hyprland.homeManagerModules.default ];

  options.modules.hyprland = {
    enable = lib.options.mkEnableOption "hyprland"; 
  };

  config = mkIf cfg.enable {

    modules.anyrun.enable = true;

    home.packages = with pkgs; [ 
      gnome.nautilus
      wofi
      wezterm
      waybar
    ];

    xdg.configFile."hypr/local.conf".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/home-manager/hypr/local.conf";

    wayland.windowManager.hyprland = {
      enable = true;
      extraConfig = ''
        exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        source = ~/.config/hypr/local.conf
      '';
    };

  };

}
