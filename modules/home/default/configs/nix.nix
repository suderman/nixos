{...}: {
  # no nix.settings.substituters here
  # no nix.settings.trusted-public-keys here

  # Bounce user services when switching
  systemd.user.startServices = "sd-switch";
}
