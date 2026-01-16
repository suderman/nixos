{flake, ...}: {
  imports = [
    flake.homeModules.default
    # flake.homeModules.desktop.hyprland
    # flake.homeModules.users.jon
  ];

  # # Hyprland on AMD desktop
  # wayland.windowManager.hyprland = {
  #   settings.exec-once = ["freetube" "zwift"];
  #   enablePlugins = true; # set false if plugins barf errors
  # };
  #
  # programs.zwift.enable = true; # fitness
}
