{...}: {
  # App Store
  services.flatpak.enable = true;

  # No unexpected reboots shortly after waking up the laptop/desktop
  system.autoUpgrade.allowReboot = false;
}
