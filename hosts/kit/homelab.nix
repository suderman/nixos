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

  services.pipewire.wireplumber.extraConfig."51-alc4082-spdif" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {"node.name" = "alsa_output.usb-Generic_USB_Audio-00.HiFi__SPDIF__sink";}
        ];
        actions.update-props."session.suspend-timeout-seconds" = 0;
      }
    ];
  };

  systemd.user.services.audioProfiles = {
    description = "Set default audio profiles";
    after = ["graphical-session.target" "wireplumber.service"];
    requires = ["graphical-session.target" "wireplumber.service"];
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    path = with pkgs; [pulseaudio];
    script = ''
      for _ in {1..100}; do
        cards=$(pactl list short cards 2>/dev/null || true)
        if grep -Fq alsa_card.pci-0000_01_00.1 <<< "$cards" &&
          grep -Fq alsa_card.usb-Generic_USB_Audio-00 <<< "$cards"; then
          pactl set-card-profile alsa_card.pci-0000_01_00.1 output:hdmi-stereo
          pactl set-card-profile alsa_card.usb-Generic_USB_Audio-00 HiFi
          exit 0
        fi
        sleep 0.1
      done

      echo "Timed out waiting for audio cards" >&2
      exit 1
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
