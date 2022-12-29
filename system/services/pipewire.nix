{ config, lib, pkgs, ... }:

let
  cfg = config.services.pipewire;

in {

  # # services.pipewire.enable = true;
  # services.pipewire = {
  #   # config.pipewire = {
  #   #   "context.modules" = [
  #   #     { name = "libpipewire-module-link-factory"; }
  #   #     { name = "libpipewire-module-session-manager"; }
  #   #     { name = "libpipewire-module-zeroconf-discover"; }
  #   #     { name = "libpipewire-module-raop-discover"; }
  #   #   ];
  #   # };
  #   pulse.enable = true;
  #   jack.enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   # audio = on;
  #   # jack = on;
  #   # alsa = on;
  #   # pulse = on;
  #   # wireplumber.enable = true;
  # };
  #
  # security.rtkit.enable = lib.mkIf cfg.enable true;
  # hardware.pulseaudio.enable = lib.mkIf cfg.enable false;

}
