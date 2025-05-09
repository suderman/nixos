{ config, lib, pkgs, this, ... }: {

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

}
