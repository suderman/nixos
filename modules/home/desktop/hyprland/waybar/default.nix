{flake, ...}: {
  imports = flake.lib.ls ./.;
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.bar = {
      layer = "top";
      position = "top"; # or bottom
      height = 39;
      exclusive = true;
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

  # We'll write our own CSS
  stylix.targets.waybar.addCss = false;

  # Pretty animations in hyprland
  wayland.windowManager.hyprland.settings.animations.layerrule = [
    "animation slide, waybar"
  ];

  home.localStorePath = [
    ".config/waybar/config"
    ".config/waybar/style.css"
  ];
}
