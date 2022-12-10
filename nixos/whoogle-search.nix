{ inputs, config, pkgs, lib, ... }: 
  
let 
  localDomain = "local.${config.networking.domain}";
  hostDomain = "${config.networking.hostName}.${config.networking.domain}";
  labels = name: [
    "--label=traefik.enable=true"
    "--label=traefik.http.routers.${name}.rule=Host(`${name}.${config.networking.hostName}.${config.networking.domain}`) || Host(`${name}.local.${config.networking.domain}`)"
    "--label=traefik.http.routers.${name}.tls.certresolver=resolver-dns"
  ];
in {

  virtualisation.oci-containers.containers."whoogle-search" = {
    image = "benbusby/whoogle-search";
    # ports = [ "5000:5000" ]; #server locahost : docker localhost
    extraOptions = [
      "--label=traefik.enable=true"
      "--label=traefik.http.routers.whoogle-search.rule=Host(`whoogle.${hostDomain}`)"
      "--label=traefik.http.routers.whoogle-search.tls.certresolver=resolver-dns"
    ];
  };

  # services.traefik.dynamicConfigOptions.http.routers."whoogle-search" = {
  #   entrypoints = "websecure";
  #   rule = "Host(`search.${localDomain}`) || Host(`search.${hostDomain}`)";
  #   service = "whoogle-search";
  #   tls.certresolver = "resolver-dns";
  #   tls.domains = [
  #     { main = "${localDomain}"; sans = "*.${localDomain}"; }
  #     { main = "${hostDomain}"; sans = "*.${hostDomain}"; }
  #   ];
  # };
  #
  # services.traefik.dynamicConfigOptions.http.services."whoogle-search" = {
  #   loadBalancer.servers = [{ url = "http://127.0.0.1:5000"; }];
  # };

  # services.nginx.enable = true;
  # services.nginx.virtualHosts."search.cog" = {
  #   enableACME = false;
  #   forceSSL = false;
  #   # locations."/".proxyPass = "http://localhost:8082";
  #   locations."/".proxyPass = "http://localhost:5000";
  # };


  virtualisation.oci-containers.containers."morning" = {
    image = "traefik/whoami";
    extraOptions = labels "morning";
    # extraOptions = [ 
    #   "--label=traefik.enable=true"
    #   "--label=traefik.http.routers.greeting.rule=Host(`greeting.${hostDomain}`) || Host(`greeting.${localDomain}`)"
    #   "--label=traefik.http.routers.greeting.tls.certresolver=resolver-dns"
    # ];
  };

}
