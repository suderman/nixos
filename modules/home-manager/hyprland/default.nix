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

    home.packages = with pkgs; [ 
      anyrun 
      gnome.nautilus
      wofi
      wezterm
      waybar
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      extraConfig = builtins.readFile ./hyprland.conf;
    };

  };

}
