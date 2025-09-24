{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.users.jon
  ];

  # Music daemon
  services.mpd = {
    enable = true;
    musicDirectory = "/media/music";
  };
}
