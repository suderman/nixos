# modules.ocis.enable = true;
{ config, pkgs, lib, ... }: 

let 

  cfg = config.modules.ocis;
  client = pkgs.unstable.owncloud-client;
  inherit (config.home) homeDirectory;
  inherit (lib) mkIf mkForce makeBinPath;

  # The ownCloud client automatically creates a directory in home called "~/ownCloud - My Name"
  # This is the default folder sync connection even though I've configurated a custom one called "~/data"
  # The script below deletes the unused default folder (only if it is empty)
  # https://central.owncloud.org/t/default-folder-created-at-each-start/44101
  script = with pkgs; writeShellScript "owncloud-client-clean" ''
    PATH=${makeBinPath [ coreutils findutils ]}
    set -euxo pipefail
    sleep 5
    find "${homeDirectory}" -maxdepth 1 -type d -name "ownCloud - *" -exec rm -rd {} +
  '';

in {

  options.modules.ocis = {
    enable = lib.options.mkEnableOption "ocis"; 
  };

  config = mkIf cfg.enable {

    home.packages = [ client pkgs.unstable.qt6.qtwayland ]; 

    services.owncloud-client = {
      enable = true;
      package = client;
    };

    systemd.user.services.owncloud-client.Service = {
      Restart = "always";
      ExecStart = with pkgs; mkForce (writeShellScript "ocis-start" ''
        PATH=${makeBinPath [ coreutils client ]}
        sleep 10 
        owncloud;
      '');
    };

    # Run the clean script when the owncloud-client service starts up
    systemd.user.services.owncloud-client-clean = {
      Unit = {
        Description = "Clean empty ownCloud directory from home";
        After = [ "owncloud-client.service" ];
      };
      Install.WantedBy = [ "owncloud-client.service" ];
      Service = {
        Type = "oneshot";
        ExecStart = script;
      };
    };

  };

}
