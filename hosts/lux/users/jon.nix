{
  flake,
  lib,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.users.jon
  ];

  # The data disk supplies this bind mount, not main-disk impermanence storage.
  home.directories.DATA.persist = lib.mkForce null;

  # Music daemon
  services.mpd = {
    enable = true;
    musicDirectory = "/media/music";
  };

  # Sync media, org, and profile, but not games.
  services.syncthing.enable = true;
  home.directories.GAMES.sync = lib.mkForce false;

  # Save main-disk space; Immich on lux already holds the camera roll.
  home.directories.MEDIA.syncIgnores = ["/camera"];
  home.directories.ORG.syncIgnores = ["/work"];
}
