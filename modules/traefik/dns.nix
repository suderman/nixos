{ config, lib, pkgs, this, ... }: let

  cfg = config.modules.traefik;
  inherit (builtins) length;
  inherit (lib) mkIf concatStringsSep;
  inherit (config.age) secrets;

  # Enable if Traefik is enabled and there is at least one public hostName
  enableDns = (length cfg.publicHostNames > 0) && (cfg.enable == true);

in {

  config = mkIf enableDns {

    systemd.services."traefik-dns" = {
      description = "Create public DNS records in CloudFlare when needed by Traefik";
      after = [ "multi-user.target" ];
      requires = [ "multi-user.target" ];
      wantedBy = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = [ secrets.cloudflare-env.path ];
      };
      path = with pkgs; [ cfdyndns ];
      script = concatStringsSep "\n" (
        map ( hostName: ''
          cfdyndns -t $CF_DNS_API_TOKEN -r ${hostName}
        '' ) cfg.publicHostNames
      );
    };

  };

}
