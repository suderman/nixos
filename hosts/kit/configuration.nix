{
  config,
  pkgs,
  lib,
  perSystem,
  flake,
  ...
}: let
  inherit (builtins) mapAttrs;
  inherit (lib) mkOption types;
  inherit (perSystem.self) mkApplication;
in {
  imports = [
    ./hardware-configuration.nix
    ./disk-configuration.nix
    flake.nixosModules.rtx-4070-ti-super
    flake.nixosModules.common
    flake.nixosModules.extra
    flake.nixosModules.hyprland
    flake.nixosModules.gaming
  ];
  networking.domain = "home";
  networking.firewall.allowPing = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  # Sound & Bluetooth
  hardware.bluetooth.enable = true;
  services.pipewire.enable = true;
  security.rtkit.enable = true;

  # Remove undesired route
  services.tailscale.deleteRoute = "10.1.0.0/16";

  # Allow powerkey to be intercepted, but still poweroff for longpress
  services.logind = {
    powerKey = "ignore";
    powerKeyLongPress = "poweroff";
  };

  # ---

  # Screen sharing
  services.sunshine = {
    enable = false;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  # Enable ollama server
  services.ollama = {
    enable = false;
    host = "0.0.0.0";
    openFirewall = true; # allow network access
    acceleration = "cuda";
    package = pkgs.ollama-cuda; # gpu power
    models = "/data/models/ollama"; # model storage on separate disk
  };

  # https://chat.kit/
  services.open-webui = {
    enable = false;
    package = pkgs.stable.open-webui; # https://github.com/NixOS/nixpkgs/issues/380636
    port = 11111; # default is 8080
  };
  # services.traefik.proxy."chat" = config.services.open-webui.port;

  # environment.systemPackages = with pkgs; [ goose-cli ];

  services.btrbk = {
    volumes = with config.networking; {
      "/mnt/main" = ["ssh://fit/mnt/pool/backups/${hostName}" "ssh://eve/mnt/pool/backups/${hostName}"];
      "/mnt/data" = ["ssh://fit/mnt/pool/backups/${hostName}"];
      "/mnt/game" = [];
    };
    # volumes = {
    #   "/mnt/main" = ["ssh://fit/mnt/pool/backups/kit" "ssh://eve/mnt/pool/backups/kit"];
    #   "/mnt/data" = ["ssh://fit/mnt/pool/backups/kit"];
    #   "/mnt/game" = [];
    # }
    # "/mnt/main".subvolume."storage" = {};
    # "/mnt/data".subvolume."storage" = {};
    # "/mnt/game".subvolume."storage" = {};
    # };
    # backups = with config.networking; {
    #   "/mnt/main".subvolume."storage" = {};
    #   "/mnt/main".target."ssh://fit/backups/${hostName}" = {};
    #   "/mnt/main".target."ssh://eve/backups/${hostName}" = {};
    # };
  };
}
