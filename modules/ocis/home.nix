# modules.ocis.enable = true;
{ config, lib, pkgs, this, ... }: 

let 

  cfg = config.modules.ocis;
  inherit (config.home) homeDirectory;
  inherit (lib) mkIf mkForce;
  inherit (this.lib) mkShellScript;


in {

  options.modules.ocis = {
    enable = lib.options.mkEnableOption "ocis"; 
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ owncloud-client qt6.qtwayland ];
    services.owncloud-client.enable = true;

    systemd.user.services.owncloud-client.Service = {
      Restart = "always";
      ExecStart = mkForce( mkShellScript { 
        inputs = with pkgs; [ coreutils owncloud-client ];
        text = ''
          sleep 10 
          owncloud;
        '';
      });

    };

    # The ownCloud client automatically creates a directory in home called "~/ownCloud - My Name"
    # This is the default folder sync connection even though I've configurated a custom one called "~/data"
    # The script below deletes the unused default folder (only if it is empty)
    # https://central.owncloud.org/t/default-folder-created-at-each-start/44101
    #
    # Run the clean script when the owncloud-client service starts up
    systemd.user.services.owncloud-client-clean = {
      Unit = {
        Description = "Clean empty ownCloud directory from home";
        After = [ "owncloud-client.service" ];
      };
      Install.WantedBy = [ "owncloud-client.service" ];
      Service = {
        Type = "oneshot";
        ExecStart = mkShellScript { 
          inputs = with pkgs; [ coreutils findutils ]; 
          text = ''
            sleep 5
            find "${homeDirectory}" -maxdepth 1 -type d -name "ownCloud - *" -exec rm -rd {} +
          '';
        };
      };
    };

  };

}
