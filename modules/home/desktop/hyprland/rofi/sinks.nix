# sinks
{
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
in {
  home.packages = [
    (pkgs.self.mkScript {
      name = "sinks";
      text = toString [
        "rofi-toggle"
        "-show sinks"
        "${toString cfg.args}"
      ];
    })
  ];

  programs.rofi = {
    mode.slot5 = "sinks:rofi-sinks";
    rasiConfig = [''sinks { display-name: "󰕾"; }''];
  };

  wayland.windowManager.hyprland.settings = {
    bind = [", XF86AudioMedia, exec, sinks"];
    bindsn = [
      "super_l, a&s, exec, sinks"
      "super_r, a&s, exec, sinks"
    ];
  };
}
