{ config, lib, pkgs, this, ... }: {

  # Keyboard control
  services.keyd.enable = true;

  # services.kdeconnect = {
  #   enable = true;
  #   indicator = true;
  # };

  # File sync
  services.ocis.enable = true;

  # Music daemon
  services.mpd = {
    enable = true;
    # musicDirectory = config.xdg.userDirs.music;
    musicDirectory = "/media/music";
    proxy = "lux";
  };

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
