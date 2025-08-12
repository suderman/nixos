{
  lib,
  flake,
  ...
}: {
  # Enable flakes and pipes
  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes pipe-operators";
  };

  # Binary caches
  nix.settings = {
    substituters = lib.imap1 (index: key: flake.lib.cacheUrl index key) flake.caches;
    trusted-public-keys = flake.caches;
  };

  # Bounce user services when switching
  systemd.user.startServices = "sd-switch";
}
