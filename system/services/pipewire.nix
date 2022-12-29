{ config, lib, pkgs, ... }:

let
  cfg = config.services.pipewire;

in {

  # services.pipewire.enable = true;
  services.pipewire = {
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  security.rtkit.enable = lib.mkIf cfg.enable true;
  hardware.pulseaudio.enable = lib.mkIf cfg.enable false;

}
