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
        restore_paused "yes"
        auto_update "yes"
        audio_output {
          type            "pipewire"
          name            "PipeWire"
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
          bind_to_address "0.0.0.0"
          port            "${toString( httpPort + offset )}" 
          encoder         "opus" # vorbis, mp3, flac
          bitrate         "128000" 
          format          "44100:16:2"
          always_on       "yes"
          tags            "yes"
        }
      '' + ( if cfg.proxy == "" then "" else ''
        database {
          plugin "proxy"
          host "${cfg.proxy}"
          port "${toString cfg.network.port}"
        }
      '' );
    };

    services.mpd-mpris.enable = true;
    services.mpris-proxy.enable = true;

    home.packages = with pkgs; [ 
      mpc-cli
      mpd-notification
    ];

  };

}
