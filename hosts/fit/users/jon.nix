{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.users.jon
    flake.homeModules.desktops.hyprland
  ];

  # Hyprland on AMD desktop
  wayland.windowManager.hyprland = {
    settings.exec-once = ["freetube" "zwift"];
    enablePlugins = false; # set false if plugins barf errors
  };
}
