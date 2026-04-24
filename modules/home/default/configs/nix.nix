{...}: {
  # Enable flakes and pipes
  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes pipe-operators";
  };

  # no nix.settings.substituters here
  # no nix.settings.trusted-public-keys here

  # Bounce user services when switching
  systemd.user.startServices = "sd-switch";
}
