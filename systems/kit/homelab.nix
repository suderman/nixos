{ config, lib, pkgs, this, ... }: { 

  # Experiments
  systemd.user.services.foobar = {
    description = "Foobar NixOS";
    after = [ "graphical-session.target" ];
    requires = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    environment = {
      FOO = "bar";
    };
    path = with pkgs; [ coreutils ];
    script = ''
      touch /tmp/foobar.txt
      date >> /tmp/foobar.txt
    '';
  };


  systemd.user.services.audioProfiles = {
    description = "Set default audio profiles";
    after = [ "graphical-session.target" ];
    requires = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    path = with pkgs; [ pulseaudio ];
    script = ''
      pactl set-card-profile alsa_card.pci-0000_01_00.1 output:hdmi-stereo
      pactl set-card-profile alsa_card.usb-Generic_USB_Audio-00 HiFi
    '';
  };


  file."/etc/foo" = { type = "dir"; };
  file."/etc/foo/bar" = { text = "Hello world!"; mode = 665; user = 913; };
  file."/etc/foo/symlink" = { type = "link"; source = /etc/foo/bar; };
  file."/etc/foo/resolv" = { type = "file"; mode = 775; user = "jon"; group = "users"; source = /etc/resolv.conf; };
  file."/etc/foo/srv" = { type = "dir"; source = /srv; };


  # Stable Diffusion
  services.traefik.proxy."sd" = 7860;
  services.traefik.proxy."sd.suderman.org" = 7860;

  # services.ocis = {
  #   enable = true;
  #   hostName = "ocis.kit";
  #   public = false;
  # };

  # services.silverbullet.enable = true;

  services.udev.extraRules = let 
    vendor = "0fcf"; product = "1009";
    modprobe = "${pkgs.kmod}/sbin/modprobe";
  in lib.mkAfter ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="${vendor}", ATTRS{idProduct}=="${product}", RUN+="${modprobe} usbserial vendor=0x${vendor} product=0x${product}", MODE="0666", OWNER="root", GROUP="root"
  '';

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  # services.immich = {
  #   enable = true;
  # };

  # networking.firewall = {
  #   allowedTCPPorts = [ 
  #     6600 # mpd
  #   ];
  # };

}
