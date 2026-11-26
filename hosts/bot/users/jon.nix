{flake, ...}: {
  # Mostly SSH; June's account autologins and has the synced folders.
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.jon
  ];
}
