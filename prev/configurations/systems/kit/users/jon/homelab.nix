{ config, lib, pkgs, ... }: {

  # Custom user service
  systemd.user.services.foobar-hm = {
    Unit = {
      Description = "Foobar Home-Manager";
      After = [ "graphical-session.target" ];
      Requires = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      Environment=''"FOO=bar"'';
      ExecStart = with pkgs; writeShellScript "foobar-hm" ''
        PATH=${lib.makeBinPath [ coreutils ]}
        touch /tmp/foobar-hm.txt
        date >> /tmp/foobar-hm.txt
      '';
    };
  };

  # Test agenix secrets with home-manager 
  age.secrets.withings-env.file = config.secrets.files.withings-env;
  home.sessionVariables = {
    SECRET_VALUE = "$(cat ${config.age.secrets.withings-env.path})";
  };

}
