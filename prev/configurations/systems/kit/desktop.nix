{ config, pkgs, lib, ... }: {

  # Desktop environment
  programs.hyprland = {
    enable = true; # also enables home-manager configuration
    autologin = "jon";
  };
  # services.xserver.desktopManager.gnome.enable = false;

  # Screen sharing
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  # Enable ollama server
  services.ollama = {
    enable = true;
    host = "0.0.0.0"; openFirewall = true; # allow network access
    acceleration = "cuda"; package = pkgs.ollama-cuda; # gpu power
    models = "/data/models/ollama"; # model storage on separate disk
  };

  # https://chat.kit/
  services.open-webui.enable = true;
  services.open-webui.package = pkgs.stable.open-webui; # https://github.com/NixOS/nixpkgs/issues/380636
  services.open-webui.port = 11111; # default is 8080
  services.traefik.proxy."chat" = config.services.open-webui.port;

  environment.systemPackages = with pkgs; [ 
    goose-cli
  ];

}
