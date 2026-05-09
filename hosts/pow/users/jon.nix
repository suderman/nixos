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
    enableOfficialPlugins = false; # hyprbars/hyprexpo broken on v0.55.0
  };

  programs.zwift.enable = true; # fitness
}
