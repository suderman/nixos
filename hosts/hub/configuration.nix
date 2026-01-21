{
  config,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.default
  ];

  # Boot with newfangled systemd-boot
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # Always at home in my laundry room
  networking.domain = "home";

  # Allow other devices on my LAN to access my tailnet
  services.tailscale.extraSetFlags = ["--advertise-routes=10.1.0.0/16"];

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = [
      "ssh://pow/mnt/pool/backups/${config.networking.hostName}"
      "ssh://eve/mnt/pool/backups/${config.networking.hostName}"
    ];
  };

  # Serve CA cert on http://10.2.0.2:1234
  services.traefik.caPort = 1234;

  # Hub for monitoring other machines
  services.beszel.enable = true;

  # Metrics and charts
  services.prometheus.enable = true;
  services.grafana.enable = true;

  # Notification server
  services.ntfy-sh.enable = true;

  # LAN controller
  services.unifi = {
    enable = true;
    gateway = flake.networking.zones.home.logos;
  };

  # Home automation
  services.home-assistant = {
    enable = true;
    name = "hass";
    ip = flake.networking.zones.home.hub;
    zigbee = "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_28b77f55258dec11915068e883c5466d-if00-port0";
    zwave = "/dev/serial/by-id/usb-Silicon_Labs_CP2102N_USB_to_UART_Bridge_Controller_3e535b346625ed11904d6ac2f9a97352-if00-port0";
    isy = flake.networking.zones.home.isy;
  };

  # Reverse proxy for termux syncthing webgui running on my phone
  services.traefik.proxy."syncthing-jon.phone" = "http://phone.tail:8384";
  services.traefik.extraInternalHostNames = ["syncthing-jon.phone"];
}
