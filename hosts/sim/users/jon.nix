{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.users.jon
    flake.homeModules.desktops.hyprland
  ];

  # File sync
  services.syncthing.enable = true;

  # Music daemon
  services.mpd.enable = true;
}
