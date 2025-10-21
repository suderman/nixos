# sinks
{pkgs, ...}: {
  home.packages = [
    (pkgs.self.mkScript {
      name = "sinks";
      text = "rofi-toggle -show sinks -cycle -theme-str 'window {width: 50%;}'";
    })
  ];

  programs.rofi.extraConfig.modes = ["sinks:rofi-sinks"];

  wayland.windowManager.hyprland.settings = {
    bind = [", XF86AudioMedia, exec, sinks"];
    bindsn = [
      "super_l, a&s, exec, sinks"
      "super_r, a&s, exec, sinks"
    ];
  };
}
