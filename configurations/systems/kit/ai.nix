{ config, pkgs, lib, ... }: {

  # Enable ollama server
  services.ollama = {
    enable = true;
    host = "0.0.0.0"; openFirewall = true; # allow network access
    acceleration = "cuda"; package = pkgs.ollama-cuda; # gpu power
    models = "/data/models/ollama"; # model storage on separate disk
  };

  # https://chat.kit/
  services.open-webui.enable = true;
  services.traefik.proxy."chat" = config.services.open-webui.port;

  environment.systemPackages = with pkgs; [ 
    goose-ai
  ];

}
