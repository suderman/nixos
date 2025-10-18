{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.jon
  ];

  # File sync
  services.syncthing.enable = true;

  # Music daemon
  services.mpd.enable = true;
}
