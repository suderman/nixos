# modules.ocis.enable = true;
{ config, lib, pkgs, this, ... }:
  
let 

  # https://github.com/owncloud/ocis/releases
  version = "4.0.3";

  cfg = config.modules.ocis;
  secrets = config.age.secrets;

  ownership = "${toString config.ids.uids.ocis}:${toString config.ids.gids.ocis}";
  signingKey = "idp-private-key.pem";
  encryptionSecret = "idp-encryption.key";

  inherit (lib) mkIf mkOption mkBefore types;
  inherit (this.lib) extraGroups;

in {

  options.modules.ocis = {
    enable = lib.options.mkEnableOption "ocis"; 
    hostName = mkOption {
      type = types.str;
      default = "ocis.${config.networking.fqdn}";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/ocis";
    };
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.ocis = 270;
    ids.gids.ocis = 270;

    users = {
      users = {

        # Create user
        ocis = {
          isSystemUser = true;
          group = "ocis";
          description = "ocis daemon user";
          home = cfg.dataDir;
          uid = config.ids.uids.ocis;
        };

      # Add admins to the ocis group
      } // extraGroups this.admins [ "ocis" ];

      # Create group
      groups.ocis = {
        gid = config.ids.gids.ocis;
      };
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Docker container
    virtualisation.oci-containers.containers.ocis = {
      image = "owncloud/ocis:${version}";
      autoStart = true;

      entrypoint = "/bin/sh";
      cmd = [ "-c" "ocis init || true; ocis server" ];

      # Run as ocis user
      user = ownership;

      # Traefik labels
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.ocis.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.ocis.tls.certresolver=resolver-dns"
        "--label=traefik.http.routers.ocis.middlewares=local@file"
      ];

      environment = {
        OCIS_URL = "https://${cfg.hostName}";
        OCIS_LOG_LEVEL = "debug";
        PROXY_TLS = "false"; 
        OCIS_INSECURE = "false";
        GRAPH_LDAP_INSECURE = "true"; # https://github.com/owncloud/ocis/issues/3812
        PROXY_ENABLE_BASIC_AUTH = "true";
        IDP_SIGNING_PRIVATE_KEY_FILES = "/etc/ocis/${signingKey}";
        IDP_ENCRYPTION_SECRET_FILE = "/etc/ocis/${encryptionSecret}";
        IDM_CREATE_DEMO_USERS = "false";
      };

      # IDM_ADMIN_PASSWORD=xxxxxxxxxxxxxxx;
      # NOTIFICATIONS_SMTP_HOST=smtp.example.com;
      # NOTIFICATIONS_SMTP_PORT=587
      # NOTIFICATIONS_SMTP_SENDER=user@example.com
      # NOTIFICATIONS_SMTP_PASSWORD=xxxxxxxxxxxx
      environmentFiles = [ secrets.ocis-env.path ];
      
      volumes = [
        "${cfg.dataDir}:/var/lib/ocis"
        "${cfg.dataDir}/config:/etc/ocis"
      ];

    };

    # Extend systemd service
    systemd.services.docker-ocis = {

      # Persist sessions - regenerating these files will force all clients to reauthenticate
      # https://github.com/owncloud/ocis/issues/3540#issuecomment-1144517534
      preStart = let openssl = "${pkgs.openssl}/bin/openssl"; etc = "${cfg.dataDir}/config"; in mkBefore ''
        mkdir -p ${etc}
        [ -e ${etc}/${encryptionSecret} ] || ${openssl} rand -out ${etc}/${encryptionSecret} 32 
        [ -e ${etc}/${signingKey} ] || ${openssl} genpkey -algorithm RSA -out ${etc}/${signingKey} -pkeyopt rsa_keygen_bits:4096
        chown -R ${ownership} ${cfg.dataDir}
      '';

      # traefik should be running before this service starts
      after = [ "traefik.service" ];

      # If the proxy goes down, take down this service too
      requires = [ "traefik.service" ];

    };

  }; 

}
