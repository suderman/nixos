{ config, lib, pkgs, ... }:
  
let 
  cfg = config.services.ocis;
  name = "ocis";
  inherit (config) secrets;
  inherit (lib) mkIf;

in {
  options = {
    services.ocis.enable = lib.options.mkEnableOption name; 
  };

  # services.ocis.enable = true;
  config = with config.networking; lib.mkIf cfg.enable {

    virtualisation.oci-containers.containers.ocis = {
      image = "owncloud/ocis:2";
      entrypoint = "/bin/sh";
      cmd = [ "-c" "ocis init || true; ocis server" ];
      environment = {
        OCIS_URL = "https://ocis.${hostName}.${domain}";
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
      environmentFiles = mkIf secrets.enable [ config.age.secrets.self-env.path ];
      ports = [ "9200:9200" ]; #server locahost : docker localhost
      volumes = [
        "my_config:/etc/ocis"
        "my_data:/var/lib/ocis"
      ];
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.${name}.rule=Host(`ocis.${hostName}.${domain}`) || Host(`ocis.local.${domain}`)"
        "--label=traefik.http.routers.${name}.tls.certresolver=resolver-dns"
      ];
    };

    # Trigger a oneshot service when this docker container starts
    systemd.services.ocis = with config.virtualisation.oci-containers; lib.mkIf cgf.enable {
      serviceConfig.Type = "oneshot";
      wantedBy = [ "${backend}-ocis-init.service" ];
      script = with pkgs; ''
        ${docker}/bin/docker ps | grep ocis
      '';
    };

    # agenix
    age.secrets = with secrets; mkIf secrets.enable {
      self-env.file = self-env;
    };

  }; 

}
