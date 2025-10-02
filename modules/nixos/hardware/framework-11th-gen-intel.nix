# Framework Laptop 13
{
  config,
  lib,
  flake,
  ...
}: {
  # https://github.com/NixOS/nixos-hardware/tree/master/framework/13-inch/11th-gen-intel
  imports = [flake.inputs.hardware.nixosModules.framework-11th-gen-intel];

  # https://github.com/NixOS/nixos-hardware/blob/master/framework/13-inch/common/audio.nix
  hardware.framework.laptop13.audioEnhancement = {
    enable = lib.mkDefault false;
    rawDeviceName = lib.mkDefault "alsa_output.pci-0000_00_1f.3.analog-stereo";
  };

  # fwupdmgr update
  services.fwupd.enable = lib.mkDefault true;

  # Keyboard control
  services.keyd = {
    quirks = lib.mkDefault true;
    keyboard = config.services.keyd.internalKeyboards.framework;
  };
}
