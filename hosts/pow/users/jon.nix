{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.jon
  ];

  # Hyprland on AMD desktop
  wayland.windowManager.hyprland = {
    lua.execOnce = ["freetube" "zwift"];
    hyprbars.enable = true;
  };

  programs.zwift.enable = true; # fitness
}
