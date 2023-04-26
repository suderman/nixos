{ config, lib, pkgs, user, ... }: {

  systemd = {

    services.withings-sync = {
      enable = true;
      description = "Run withings sync";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        EnvironmentFile = config.age.secrets.withings-env.path; 
        User = "${user}";
      };
      script = "${pkgs.withings-sync}/bin/withings-sync";
    };

    timers.withings-sync = {
      wantedBy = [ "timers.target" ];
      partOf = [ "withings-sync.service" ];
      timerConfig = {
        OnCalendar = "*:0/3";
        Unit = "withings-sync.service";
      };
    };

  };

}
