# modules.lunasea.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.lunasea;
  inherit (lib) mkIf mkOption options types strings;
  inherit (builtins) toString;
  inherit (config.modules) traefik;

in {

  options.modules.lunasea = {

    enable = options.mkEnableOption "lunasea"; 

    name = mkOption {
      type = types.str;
      default = "lunasea";
    };

  };

  config = mkIf cfg.enable {

    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.lunasea = {
      image = "ghcr.io/jagandeepbrar/lunasea:stable";
      extraOptions = traefik.labels cfg.name;
    };

  };

}
