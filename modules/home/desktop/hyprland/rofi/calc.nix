# calc
{
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
in {
  home.packages = [
    (pkgs.self.mkScript {
      name = "calc";
      text = toString [
        "rofi-toggle"
        "-show calc"
        "-modi calc"
        "-no-show-match"
        "-no-sort"
        "-no-history"
        "-theme-str 'window {width: 25%;}'"
        "${toString cfg.args}"
      ];
    })
  ];

  programs.rofi = {
    plugins = [pkgs.unstable.rofi-calc];
    # mode.slot4 = "calc";
    args = ["-calc-command \"echo -n '{result}' | wl-copy\""];
    rasiConfig = [''calc { display-name: ""; }''];
  };

  wayland.windowManager.hyprland.settings.bind = [
    "super+alt, c, exec, calc"
    "alt+ctrl, insert, exec, calc"
  ];
}
