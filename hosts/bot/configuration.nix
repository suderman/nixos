{
  config,
  pkgs,
  flake,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.default
    flake.nixosModules.desktop.hyprland
  ];

  # Boot with newfangled systemd-boot
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.consoleMode = "max";
    efi.canTouchEfiVariables = true;
  };

  # June's always-on computer, wired at home
  networking.domain = "home";

  # Her desktop starts at boot without waiting for a password. A DisplayPort
  # dummy plug gives Hyprland its only output.
  services.displayManager = {
    defaultSession = "hyprland";
    autoLogin = {
      enable = true;
      user = "june";
    };
  };

  # Intel UHD 630 encodes H.264 and HEVC through VAAPI
  hardware.graphics.extraPackages = [pkgs.intel-media-driver];

  # Moonlight is the way in; noVNC (vnc-june.bot) is the browser fallback.
  services.sunshine = {
    enable = true;
    settings.encoder = "vaapi";
  };

  # Snapshots and backups
  services.btrbk.volumes = {
    "/mnt/main" = [
      "ssh://pow/mnt/pool/backups/${config.networking.hostName}"
      "ssh://eve/mnt/pool/backups/${config.networking.hostName}"
    ];
  };
}
