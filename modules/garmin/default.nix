# modules.garmin.enable = true;
{ config, lib, pkgs, this, ... }:

let 

  cfg = config.modules.garmin;
  home = config.users.users."${builtins.head this.admins}".home;
  inherit (lib) mkIf mkOption types;

in {

  options.modules.garmin = {
    enable = lib.options.mkEnableOption "garmin"; 
  };

  config = mkIf cfg.enable {

    #
    systemd = let 
      device = "/run/user/1000/gvfs/mtp:host=091e_4cda_0000cb7d522d/Primary";
      target = "${home}/data/watch";
    in { 

      # Watch the "old" path and when it exists, trigger the ssmv service
      paths.garmin = {
        wantedBy = [ "paths.target" ];
        pathConfig = {
          PathExists = device;
          Unit = "garmin.service";
        };
      };

      # Move all files inside the "old" directory into the "new" and delete the "old" directory
      services.garmin = {
        description = "Sync Garmin";
        requires = [ "garmin.path" ];
        serviceConfig.Type = "oneshot";
        path = [ pkgs.rsync ];
        script = "rsync -a ${device}/Podcasts/* ${target}/";
      };

    };

  };

}
