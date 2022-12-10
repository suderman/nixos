{ inputs, config, pkgs, lib, ... }:

let 
  localDomain = "local.${config.networking.domain}";
  hostDomain = "${config.networking.hostName}.${config.networking.domain}";

in {

  # https://github.com/owncloud/ocis/blob/master/deployments/examples/ocis_traefik/docker-compose.yml
  virtualisation.oci-containers.containers."owncloud-ocis" = {
    image = "owncloud/ocis:2";
    entrypoint = "/bin/sh";
    cmd = [ "-c" "ocis init || true; ocis server" ];
    extraOptions = [ "--network=host" ];
    environment = {
      OCIS_URL = "https://ocis.${hostDomain}";
      OCIS_LOG_LEVEL = "debug";
      PROXY_TLS = "false"; 
      OCIS_INSECURE = "false";
      GRAPH_LDAP_INSECURE = "true"; # https://github.com/owncloud/ocis/issues/3812
      PROXY_ENABLE_BASIC_AUTH = "true";
      # IDP_SIGNING_PRIVATE_KEY_FILES = "/etc/ocis/idp-private-key.pem";
      # IDP_ENCRYPTION_SECRET_FILE = "/etc/ocis/idp-encryption.key";
      IDM_ADMIN_PASSWORD = "secret"; # this overrides the admin password from the configuration file
      IDM_CREATE_DEMO_USERS = "false";
      # NOTIFICATIONS_SMTP_HOST: ${SELF_SMTP_HOST}
      # NOTIFICATIONS_SMTP_PORT: ${SELF_SMTP_PORT}
      # NOTIFICATIONS_SMTP_SENDER: ${SELF_SMTP_NAME}
      # NOTIFICATIONS_SMTP_PASSWORD: ${SELF_SMTP_PASSWORD}
    };
    ports = [ "9200:9200" ]; #server locahost : docker localhost
    volumes = [
      "my_config:/etc/ocis"
      "my_data:/var/lib/ocis"
    ];
  };

  services.traefik.dynamicConfigOptions.http.routers."owncloud-ocis" = {
    entrypoints = "websecure";
    rule = "Host(`ocis.${localDomain}`) || Host(`ocis.${hostDomain}`)";
    service = "owncloud-ocis";
    tls.certresolver = "resolver-dns";
    tls.domains = [
      { main = "${localDomain}"; sans = "*.${localDomain}"; }
      { main = "${hostDomain}"; sans = "*.${hostDomain}"; }
    ];
  };
  services.traefik.dynamicConfigOptions.http.services."owncloud-ocis" = {
    loadBalancer.servers = [{ url = "http://127.0.0.1:9200"; }];
  };

  # systemd.services.create-ocis-pod = with config.virtualisation.oci-containers; {
  #   serviceConfig.Type = "oneshot";
  #   wantedBy = [ "${backend}-ocis.service" ];
  #   script = ''
  #     ${pkgs.podman}/bin/podman pod exists elk || \
  #       ${pkgs.podman}/bin/podman pod create -n ocis -p '127.0.0.1:9200:9200'
  #   '';
  # };

}
