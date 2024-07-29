# services.ocis.enable = true;
{ config, lib, pkgs, this, ... }:
  
let 

  cfg = config.services.ocis;

  inherit (lib) extraGroups getExe mkBefore mkForce mkIf mkOption toOwnership types;
  inherit (config.age) secrets;
  inherit (config.services.traefik.lib) mkHostName;
  inherit (config.ids) uids gids;

in {

  options.services.ocis = {
    name = mkOption {
      type = types.str;
      default = "ocis";
    };
    hostName = mkOption {
      type = types.str;
      default = (mkHostName cfg.name);
    };
    public = mkOption {
      type = with lib.types; nullOr bool;
      default = null;
    };
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.ocis = 270;
    ids.gids.ocis = 270;

    users = {
      users = {

        # Set uid
        "${cfg.user}".uid = uids.ocis;

      # Add admins to the ocis group
      } // extraGroups this.admins [ cfg.group ];

      # Set gid
      groups."${cfg.group}".gid = gids.ocis;

    };

    services.traefik = {
      enable = true;
      proxy.${cfg.hostName} = {
        url = "http://${cfg.address}:${toString cfg.port}"; # origin address (with http://)
        public = cfg.public;
      };
    };

    # Configure service
    services.ocis = {
      address = "${cfg.name}.${this.hostName}"; port = 9200; # origin address (without http://)
      url = "https://${cfg.hostName}"; # public address (with https://)
      configDir = "${cfg.stateDir}/config";
      environment = {
        PROXY_TLS = "false"; # make origin use http://
        OCIS_INSECURE = "true"; # allow self-signed certs
        PROXY_ENABLE_BASIC_AUTH = "true"; # needed for WebDav clients without OpenID Connect
        IDP_SIGNING_PRIVATE_KEY_FILES = "${cfg.configDir}/idp-private-key.pem";
        IDP_ENCRYPTION_SECRET_FILE = "${cfg.configDir}/idp-encryption.key";
      };
    };

    # Initialize configuration
    systemd.services.ocis-init = {
      enable = true;
      description = "Setup ocis config & keys";
      wantedBy = [ "multi-user.target" ];
      after = [ "traefik.service" ]; 
      before = [ "ocis.service" ];
      wants = with config.systemd.services.ocis; after ++ before; 
      serviceConfig.Type = "oneshot";
      # Persist sessions - regenerating these files will force all clients to reauthenticate
      # https://github.com/owncloud/ocis/issues/3540#issuecomment-1144517534
      script = let 
        ocis = getExe cfg.package; 
        openssl = "${pkgs.openssl}/bin/openssl"; 
        signingKey = cfg.environment.IDP_SIGNING_PRIVATE_KEY_FILES;
        encryptionSecret = cfg.environment.IDP_ENCRYPTION_SECRET_FILE;
      in ''
        mkdir -p ${cfg.configDir}
        [ -e ${encryptionSecret} ] || ${openssl} rand -out ${encryptionSecret} 32 
        [ -e ${signingKey} ] || ${openssl} genpkey -algorithm RSA -out ${signingKey} -pkeyopt rsa_keygen_bits:4096
        [ -e ${cfg.configDir}/ocis.yaml ] || ${ocis} init --config-path ${cfg.configDir} --insecure true
        chown -R ${toOwnership uids.ocis gids.ocis} ${cfg.stateDir}
      '';
    };

  }; 

}
