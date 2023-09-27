# desktop = "hyprland";
{ config, pkgs, lib, inputs, desktop, ... }: 

let 

  inherit (lib) mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;

  dir = "/etc/nixos/modules/home-manager/hyprland";

in {

  # Import hyprland module
  imports = [ 
    inputs.hyprland.homeManagerModules.default 
  ];


  config = mkIf (desktop == "hyprland") {

    modules.eww.enable = true;
    # modules.anyrun.enable = true;

    home.packages = with pkgs; [ 
      gnome.nautilus
      wofi
      wezterm
      waybar
      hyprpaper
      brightnessctl
      # pamixer
      # ncpamixer
    ];

    xdg.configFile."hypr/local.conf".source = mkOutOfStoreSymlink "${dir}/local.conf";

    wayland.windowManager.hyprland = {
      enable = true;
      plugins = [
        inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
      ];
      extraConfig = ''
        exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        source = ~/.config/hypr/local.conf
      '';
    };

  };

}
