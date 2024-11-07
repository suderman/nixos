{ config, lib, pkgs, ... }: let

  cfg = config.services.mpd;
  inherit (config.home) offset;
  inherit (lib) mkIf ls mkDefault mkOption types;
  mdpPort = 6600; # default port for mpd
  httpPort = 8600; # default port for http streaming

in {

  imports = ls ./.;

  options.services.mpd = {
    proxy = mkOption {
      type = types.str;
      default = ""; # Set to host if proxying mpd database
    };
  };

  config = mkIf cfg.enable {

    services.mpd = {
      musicDirectory = mkDefault config.xdg.userDirs.music;
      network.listenAddress = "any";
      network.port = mdpPort + offset; # 6600 (or 6601, 6602, etc)
      dbFile = if cfg.proxy == "" then "${cfg.dataDir}/tag_cache" else null;
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
      '' + ( if cfg.proxy == "" then "" else ''
        database {
          plugin "proxy"
          host "${cfg.proxy}"
          port "${toString cfg.network.port}"
        }
      '' );
    };

    home.packages = with pkgs; [ 
      mpc-cli
    ];

  };

}
