{
  lib,
  pkgs,
  flake,
  ...
}: {
  # Experiments
  systemd.user.services.foobar = {
    description = "Foobar NixOS";
    after = ["graphical-session.target"];
    requires = ["graphical-session.target"];
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    environment = {
      FOO = "bar";
    };
    path = with pkgs; [coreutils];
    script = ''
      touch /tmp/foobar.txt
      date >> /tmp/foobar.txt
    '';
  };

  systemd.user.services.audioProfiles = {
    description = "Set default audio profiles";
    after = ["graphical-session.target"];
    requires = ["graphical-session.target"];
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    path = with pkgs; [pulseaudio];
    script = ''
      pactl set-card-profile alsa_card.pci-0000_01_00.1 output:hdmi-stereo
      pactl set-card-profile alsa_card.usb-Generic_USB_Audio-00 HiFi
    '';
  };

  # Stable Diffusion
  services.traefik.proxy."sd" = 7860;
  services.traefik.proxy."sd.suderman.org" = 7860;

  services.udev.extraRules = let
    vendor = "0fcf";
    product = "1009";
    modprobe = "${pkgs.kmod}/sbin/modprobe";
  in
    lib.mkAfter ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="${vendor}", ATTRS{idProduct}=="${product}", RUN+="${modprobe} usbserial vendor=0x${vendor} product=0x${product}", MODE="0666", OWNER="root", GROUP="root"
    '';

  # networking.firewall = {
  #   allowedTCPPorts = [
  #     6600 # mpd
  #   ];
  # };

  # environment.systemPackages = with pkgs; [ goose-cli ];

  # services.ocis = {
  #   enable = true;
  #   hostName = "ocis.kit";
  #   public = false;
  # };

  # services.silverbullet.enable = true;

  services.home-assistant = {
    enable = false;
    name = "hass";
    ip = flake.networking.zones.tail.kit;
  };

  # LAN controller
  services.unifi = {
    enable = false;
    gateway = flake.networking.zones.home.logos;
  };

  services.prometheus.enable = false;
  services.grafana.enable = false;
}
