{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.traefik;
  # Enable if Traefik is enabled and there is at least one public hostName
  enableDns = (builtins.length cfg.publicHostNames > 0) && (cfg.enable == true);
in {
  config = lib.mkIf enableDns {
    systemd.services."traefik-dns" = {
      description = "Create public DNS records in CloudFlare when needed by Traefik";
      after = ["multi-user.target"];
      requires = ["multi-user.target"];
      wantedBy = ["sysinit.target"];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = [config.age.secrets.cloudflare-env.path];
      };
      path = with pkgs; [cfdyndns];
      script = lib.concatStringsSep "\n" (
        map (hostName: ''
          cfdyndns -t $CF_DNS_API_TOKEN -r ${hostName}
        '')
        cfg.publicHostNames
      );
    };
  };
}
