{ config, osConfig, lib, pkgs, ... }: let

  cfg = osConfig.services.mpd;
  inherit (lib) mkIf ls;

  # 6600 or 6601 or 6602 or ...
  port = cfg.network.port + (config.home.uid - 1000); 

in {

  imports = ls ./.;

  config = mkIf cfg.enableUser {

    home.packages = with pkgs; [ 
      mpc-cli
    ];

    services.mpd = {
      enable = true;
      musicDirectory = config.xdg.userDirs.music;
      network.listenAddress = "any";
      network.port = port;
      extraConfig = ''
        audio_output {
          type "pulse"
          name "PulseAudio"
        }
      '';
    };

  };

}
