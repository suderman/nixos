{ config, lib, perSystem, ... }: let

  cfg = config.services.mpd;
  inherit (lib) mkIf;
  inherit (perSystem.self) mkScript mpd-url;

in {

  config = mkIf cfg.enable {

    home.packages = [ mpd-url ];

    # Watch for mpd playlist changes and update http songs
    systemd.user = {

      services.mpd-url = {
        Unit = {
          Description = "mpd-url";
          After = [ "mpd.service" ];
          Requires = [ "mpd.service" ];
        };
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "simple";
          Restart = "always";
          ExecStart = mkScript {
            path = [ mpd-url ];
            text = ''
              mpd-url watch localhost ${toString cfg.network.port}
            '';
          };
        };
      };
      
      services.mpd-url-update = {
        Unit = {
          Description = "mpd-url update";
          After = [ "mpd.service" ];
          Requires = [ "mpd.service" ];
        };
        Install.WantedBy = [ "default.target" ];
        Service = {
          Type = "oneshot";
          ExecStart = mkScript {
            path = [ mpd-url ];
            text = ''
              mpd-url update localhost ${toString cfg.network.port}
            '';
          };
        };
      };

      timers.mpd-url-update = {
        Unit.Description = "mpc-url update";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnCalendar = "*-*-* 0/2:00:00";  # Every 2 hours
          Persistent = true;
        };
      };

    };

  };

}
