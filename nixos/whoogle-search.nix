{ inputs, config, pkgs, lib, ... }: 
  
  let domain = "example.com";

in {

  virtualisation.oci-containers.containers."whoogle-search" = {
    image = "benbusby/whoogle-search";
    ports = [ "5000:5000" ]; #server locahost : docker localhost
  };

  services.traefik.dynamicConfigOptions.http.routers."whoogle-search" = {
    entrypoints = "websecure";
    rule = "Host(`search.local.${domain}`) || Host(`search.cog.${domain}`)";
    service = "whoogle-search";
    tls.certresolver = "resolver-dns";
    tls.domains = [
      { main = "local.${domain}"; sans = "*.local.${domain}"; }
      { main = "cog.${domain}"; sans = "*.cog.${domain}"; }
    ];
  };

  services.traefik.dynamicConfigOptions.http.services."whoogle-search" = {
    loadBalancer.servers = [{ url = "http://127.0.0.1:5000"; }];
  };

  # services.nginx.enable = true;
  # services.nginx.virtualHosts."search.cog" = {
  #   enableACME = false;
  #   forceSSL = false;
  #   # locations."/".proxyPass = "http://localhost:8082";
  #   locations."/".proxyPass = "http://localhost:5000";
  # };

}
