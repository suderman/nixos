# modules.silverbullet.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.silverbullet;
  inherit (lib) mkIf mkOption options types strings;
  inherit (builtins) toString;

in {

  options.modules.silverbullet = {

    enable = options.mkEnableOption "silverbullet"; 

    hostName = mkOption {
      type = types.str;
      default = "silverbullet.${config.networking.fqdn}";
      description = "FQDN for the SilverBullet instance";
    };

  };

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.silverbullet = {
      image = "zefhemel/silverbullet:0.5.3";
      volumes = [ "space:/space" ];
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.silverbullet.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.silverbullet.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.silverbullet.middlewares=local@file"
      ];
    };

  };

}
