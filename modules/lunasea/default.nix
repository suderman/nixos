# services.lunasea.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.services.lunasea;
  inherit (lib) ls mkIf mkOption options types strings;
  inherit (builtins) toString;
  inherit (config.modules) traefik;

in {

  # Launch services this front-end controls
  imports = ls ./.;

  options.services.lunasea = {
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
