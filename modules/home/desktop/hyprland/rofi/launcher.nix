{pkgs, ...}: {
  programs.rofi = {
    plugins = [pkgs.unstable.rofi-emoji];
    extraConfig = {
      modes = ["combi" "hyprland:rofi-hyprland" "emoji"];
      combi-modes = ["hyprland" "drun" "ssh"];
    };
  };

  # launcher
  home.packages = [
    (pkgs.self.mkScript {
      name = "launcher";
      text = "rofi-toggle -show combi";
    })
  ];

  # Left Super is app launcher/switcher
  wayland.windowManager.hyprland.settings = {
    bindr = ["super, Super_L, exec, launcher"];
    bind = ["super, space, exec, launcher"];
  };
}
