{...}: {
  # Sound & Bluetooth
  services.pipewire.enable = true;
  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;
}
