# calc
{pkgs, ...}: {
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
        "-calc-command \"echo -n '{result}' | wl-copy\""
        "-theme-str 'window {width: 25%;}'"
      ];
    })
  ];

  programs.rofi = {
    plugins = [pkgs.unstable.rofi-calc];
    extraConfig.modes = ["calc"];
  };

  wayland.windowManager.hyprland.settings.bind = [
    "super+alt, c, exec, calc"
    "alt+ctrl, insert, exec, calc"
  ];
}
