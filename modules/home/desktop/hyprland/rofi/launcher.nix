{
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.rofi;
in {
  programs.rofi = {
    mode.slot1 = "combi";
    extraConfig.combi-modes = ["hyprland:rofi-hyprland" "drun" "run" "ssh"];
    rasiConfig = [
      ''
        combi { display-name: ""; }
        hyprland { display-name: ""; }
        drun { display-name: "󰌧"; }
        run { display-name: ""; }
        ssh { display-name: ""; }
      ''
    ];
  };

  # launcher
  home.packages = [
    (pkgs.self.mkScript {
      name = "launcher";
      text = "rofi-toggle -show combi ${toString cfg.args}";
    })
  ];

  # Left Super is app launcher/switcher
  wayland.windowManager.hyprland.settings = {
    bindr = ["super, Super_L, exec, launcher"];
    bind = ["super, space, exec, launcher"];
  };
}
