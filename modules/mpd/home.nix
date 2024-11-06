{ config, lib, pkgs, ... }: let

  cfg = config.services.mpd;
  inherit (config.home) offset;
  inherit (lib) mkIf ls mkDefault;
  mdpPort = 6600; # default port for mpd
  httpPort = 8600; # default port for http streaming

in {

  imports = ls ./.;

  config = mkIf cfg.enable {

    services.mpd = {
      musicDirectory = mkDefault config.xdg.userDirs.music;
      network.listenAddress = "any";
      network.port = mdpPort + offset; # 6600 (or 6601, 6602, etc)
      extraConfig = ''
        audio_output {
          type            "pulse"
          name            "PulseAudio"
        }
        audio_output {
          type            "fifo"
          name            "Visualizer feed"
          path            "/tmp/mpd${toString offset}.fifo"
          format          "44100:16:2"
          buffer_time     "10000"
        }
        audio_output {
          type            "httpd"
          name            "HTTP stream"
          encoder         "vorbis" # vorbis, mp3, flac
          bind_to_address "0.0.0.0"
          port            "${toString( httpPort + offset )}" 
          quality         "4.0"      
          format          "44100:16:2"
        }
      '';
    };

    home.packages = with pkgs; [ 
      mpc-cli
    ];

  };

}
