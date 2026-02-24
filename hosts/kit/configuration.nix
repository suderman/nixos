{
  config,
  pkgs,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.hardware.rtx-4070-ti-super
    flake.nixosModules.default
    flake.nixosModules.desktop.hyprland
    ./homelab.nix
  ];

  # Boot with newfangled systemd-boot
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # Always at home in my office
  networking.domain = "home";

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  # Allow powerkey to be intercepted, but still poweroff for longpress
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };

  # Snapshots and backups
  services.btrbk.volumes = with config.networking; {
    "/mnt/main" = [
      "ssh://pow/mnt/pool/backups/${hostName}"
      "ssh://eve/mnt/pool/backups/${hostName}"
    ];
    "/mnt/data" = ["ssh://pow/mnt/pool/backups/${hostName}"];
    "/mnt/game" = [];
  };

  # Screen sharing
  services.sunshine = {
    enable = false;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  # Enable ollama server
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true; # allow network access
    acceleration = "cuda";
    package = pkgs.ollama-cuda; # gpu power
    models = "/data/models/ollama"; # model storage on separate disk
  };

  # https://chat.kit/
  services.open-webui = {
    enable = false;
    package = pkgs.open-webui; # https://github.com/NixOS/nixpkgs/issues/380636
    port = 11111; # default is 8080
  };
  # services.traefik.proxy."chat" = config.services.open-webui.port;

  services.immich.enable = false;

  services.forgejo = {
    enable = true;
    name = "git";
  };

  # Garmin fenix 6 pro
  hardware.garmin.deviceId = "091e:4cda";

  # Printer/scanner
  services.printing = {
    enable = true;
    browsing = true;
    drivers = [pkgs.hplipWithPlugin];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.sane = {
    enable = true;
    extraBackends = [pkgs.hplipWithPlugin];
  };

  services.usbmuxd.enable = true;

  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse

    hplipWithPlugin
    system-config-printer
    sane-backends
    sane-frontends
    simple-scan
  ];
}
