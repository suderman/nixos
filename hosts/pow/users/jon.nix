{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.jon
  ];

  # Hyprland on AMD desktop
  wayland.windowManager.hyprland = {
    lua = {
      enable = true;
      execOnce = ["freetube" "zwift"];
    };
    enablePlugins = false; # dynamic cursors crash on lua path for now
    enableOfficialPlugins = true;
  };

  programs.zwift.enable = true; # fitness
}
