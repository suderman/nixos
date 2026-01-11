{
  lib,
  flake,
  ...
}: let
  inherit (builtins) attrNames attrValues;
  inherit (lib) imap1;
in {
  # Enable flakes and pipes
  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes pipe-operators";
  };

  # Binary caches
  nix.settings = {
    substituters = imap1 (i: url: "${url}?priority=${toString i}") (attrNames flake.caches);
    trusted-public-keys = attrValues flake.caches;
  };

  # Bounce user services when switching
  systemd.user.startServices = "sd-switch";
}
