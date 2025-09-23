{pkgs, ...}: {
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
    package = pkgs.open-webui; # https://github.com/NixOS/nixpkgs/issues/380636
    port = 11111; # default is 8080
  };
  # services.traefik.proxy."chat" = config.services.open-webui.port;

  services.immich.enable = false;
  # services.garmin.enable = true;
}
