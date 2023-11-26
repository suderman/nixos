# modules.restic.enable = true;
{ config, lib, pkgs, ... }: 

let 

  cfg = config.modules.restic;
  secrets = config.age.secrets;
  inherit (lib) mkIf mkOption mkForce types recursiveUpdate;

in {

  options.modules.restic = {
    enable = lib.options.mkEnableOption "restic"; 
    paths =  mkOption { type = types.listOf (types.str); default = [];};
    exclude =  mkOption { type = types.listOf (types.str); default = [];};
    # execStartPre = mkOption { type = types.str; }; # TODO: hook into this on order to prepare i.e. postgres backups
    # TODO: set services.restic.backups.<name>.repository destination repo from machine config
  };

  # Use restic to snapshot persistent states and home
  config = mkIf cfg.enable {

    services.restic.backups = let 
      paths = [
        "/nix/state"
      ];
      exclude = [
        "/nix/state/var/lib/docker/overlay2" # Do not keep the image overlays but all the rest, i.e. volumes
      ];
    in {      
      azureBlob =  {
        paths = paths ++ cfg.paths;
        exclude = exclude ++ cfg.exclude;
        environmentFile = secrets.restic-azure-env.path;
        passwordFile = secrets.alphanumeric-secret.path;
        repository = "azure:backup:/";
        initialize = true;
        timerConfig.OnCalendar = "*-*-* *:00:00";
        timerConfig.RandomizedDelaySec = "5m";
      };
    };
  };
}
