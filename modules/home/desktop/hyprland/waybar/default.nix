{flake, ...}: {
  imports = flake.lib.ls ./.;
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.bar = {
      layer = "top";
      position = "top"; # or bottom
      exclusive = true;
      height = 30;
      persistent_workspaces = {
        "1" = [];
        "2" = [];
        "3" = [];
        "4" = [];
        "5" = [];
        "6" = [];
        "7" = [];
        "8" = [];
        "9" = [];
        "10" = [];
      };
    };

    style = builtins.readFile ./style.css;
  };

  stylix.targets.waybar.addCss = false; # we'll write our own CSS
  stylix.targets.waybar.font = "sansSerif"; # not monospace

  wayland.windowManager.hyprland.settings = {
    # animations.layerrule = ["animation slide, waybar"]; # slick animations
    animations.layerrule = ["animation slide, blur on, match:namespace waybar"]; # slick animations
    # layerrule = ["blur,waybar"]; # blur the bar
    layerrule = ["blur on, match:namespace waybar"]; # blur the bar
  };

  home.localStorePath = [
    ".config/waybar/config"
    ".config/waybar/style.css"
  ];
}
