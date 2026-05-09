{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.jon
  ];

  # Hyprland on AMD desktop
  wayland.windowManager.hyprland = {
    settings.exec-once = ["freetube" "zwift"];
    enablePlugins = true; # dynamic cursors work on v0.55.0
    enableOfficialPlugins = false; # hyprbars/hyprexpo broken on v0.55.0
  };

  programs.zwift.enable = true; # fitness
}
