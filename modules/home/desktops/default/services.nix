{...}: {
  # App Store
  services.flatpak.enable = true;
  # Remember audio settings
  persist.storage.directories = [".local/state/wireplumber"];
}
