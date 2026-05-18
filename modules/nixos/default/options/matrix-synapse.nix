# services.matrix-synapse.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.services.matrix-synapse;
  inherit (lib) concatMapStringsSep mkAfter mkBefore mkForce mkIf mkOption types;
  inherit (config.services.traefik.lib) mkHostName;

  hostName = mkHostName cfg.name;
  wellKnownPort = cfg.port + 1;
  localUserNames = builtins.attrNames cfg.localUsers;
in {
  # This extends the upstream NixOS Synapse module with the repo's private
  # service conventions: Traefik routing, deterministic secrets, PostgreSQL,
  # and optional local user bootstrapping.
  options.services.matrix-synapse = {
    name = mkOption {
      type = types.str;
      default = "matrix";
    };

    port = mkOption {
      type = types.port;
      default = 8008;
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/matrix-synapse";
    };

    secretsFile = mkOption {
      type = types.str;
      default = "${cfg.stateDir}/secrets.yaml";
    };

    databaseName = mkOption {
      type = types.str;
      default = "matrix-synapse";
    };

    databaseUser = mkOption {
      type = types.str;
      default = "matrix-synapse";
    };

    localUsers = mkOption {
      type = types.attrsOf (types.submodule {
        options.admin = mkOption {
          type = types.bool;
          default = false;
        };
      });
      default = {};
    };
  };

  config = mkIf cfg.enable {
    # Keep Synapse secrets out of the Nix store. They are deterministic so the
    # host can be recovered from the repo's encrypted 32-byte hex, but the
    # derived values only land in /var/lib at activation time.
    system.activationScripts.matrix-synapse-secrets = let
      inherit (perSystem.self) mkScript derive;
      hex = config.age.secrets.hex.path;
      secretsDir = builtins.dirOf cfg.secretsFile;
      usersDir = "${cfg.stateDir}/users";
      text =
        # bash
        ''
          if [[ -f ${hex} ]]; then
            tmp="$(mktemp)"
            registration="$(mktemp)"
            macaroon="$(mktemp)"

            derive hex 'matrix-synapse:${hostName}:registration-shared-secret' <${hex} >"$registration"
            derive hex 'matrix-synapse:${hostName}:macaroon-secret-key' <${hex} >"$macaroon"

            install -dm750 -o matrix-synapse -g matrix-synapse "${secretsDir}"
            printf 'registration_shared_secret: "%s"\n' "$(cat "$registration")" >"$tmp"
            printf 'macaroon_secret_key: "%s"\n' "$(cat "$macaroon")" >>"$tmp"
            install -m600 -o matrix-synapse -g matrix-synapse "$tmp" "${cfg.secretsFile}"

            install -dm750 -o matrix-synapse -g matrix-synapse "${usersDir}"

            ${concatMapStringsSep "\n" (userName: ''
              password="${usersDir}/${userName}.password"

              if [[ ! -f "$password" ]]; then
                user_password="$(mktemp)"
                derive hex 'matrix-synapse:${hostName}:${userName}:password' <${hex} >"$user_password"
                install -m600 -o matrix-synapse -g matrix-synapse "$user_password" "$password"
                rm -f "$user_password"
              fi

              chown matrix-synapse:matrix-synapse "$password"
              chmod 600 "$password"
            '')
            localUserNames}

            rm -f "$tmp" "$registration" "$macaroon"
          fi
        '';
      path = [derive];
    in
      mkAfter "${mkScript {inherit text path;}}";

    services.matrix-synapse = {
      # Used by matrix-synapse-users.service for closed-registration account
      # creation. Public/self-service registration remains disabled below.
      enableRegistrationScript = true;
      extraConfigFiles = [cfg.secretsFile];

      # Force the upstream freeform settings rather than merge with defaults:
      # the default listener includes federation, which this private bus does
      # not want to expose.
      settings = mkForce {
        server_name = hostName;
        public_baseurl = "https://${hostName}/";
        # This private server uses TLS, private network access control, and
        # bots/server-side history, but intentionally keeps Matrix E2EE off.
        encryption_enabled_by_default_for_room_type = "off";
        report_stats = false;
        presence.enabled = false;
        url_preview_enabled = false;
        enable_registration = false;
        database = {
          name = "psycopg2";
          args = {
            user = cfg.databaseUser;
            database = cfg.databaseName;
            host = "/run/postgresql";
          };
        };
        listeners = mkForce [
          {
            port = cfg.port;
            # Synapse is only reachable through local Traefik. Traefik then
            # applies this repo's internal DNS, private CA, and local allowlist.
            bind_addresses = ["127.0.0.1"];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = lib.mkForce [
              {
                names = ["client"];
                compress = true;
              }
            ];
          }
        ];
      };
    };

    services.postgresql.enable = true;

    # Only create the role here. The database itself must be created with C/C
    # locale for Synapse, so matrix-synapse-database.service handles it.
    services.postgresql = {
      ensureUsers = [
        {
          name = cfg.databaseUser;
        }
      ];
    };

    # Synapse rejects PostgreSQL databases whose LC_COLLATE/LC_CTYPE are not C.
    # The repo's shared PostgreSQL module creates databases with the cluster
    # locale, so this unit creates or safely repairs the Synapse DB explicitly.
    systemd.services.matrix-synapse-database = {
      description = "Prepare Matrix Synapse PostgreSQL database";
      after = [
        "postgresql.service"
        "postgresql-setup.service"
      ];
      before = ["matrix-synapse.service"];
      requires = [
        "postgresql.service"
        "postgresql-setup.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        Group = "postgres";
        RemainAfterExit = true;
      };
      path = [config.services.postgresql.finalPackage];
      script =
        # bash
        ''
          database_name=${lib.escapeShellArg cfg.databaseName}
          database_user=${lib.escapeShellArg cfg.databaseUser}

          database_exists="$(psql -v ON_ERROR_STOP=1 -d postgres -tAc "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$database_name');")"

          if [[ "$database_exists" == "f" ]]; then
            createdb \
              --template=template0 \
              --owner="$database_user" \
              --lc-collate=C \
              --lc-ctype=C \
              "$database_name"
            exit 0
          fi

          database_locale="$(psql -v ON_ERROR_STOP=1 -d postgres -tAc "SELECT datcollate || '/' || datctype FROM pg_database WHERE datname = '$database_name';")"

          if [[ "$database_locale" == "C/C" ]]; then
            exit 0
          fi

          user_tables="$(psql -v ON_ERROR_STOP=1 -d "$database_name" -tAc 'SELECT count(*) FROM pg_stat_user_tables;')"

          if [[ "$user_tables" == "0" ]]; then
            dropdb "$database_name"
            createdb \
              --template=template0 \
              --owner="$database_user" \
              --lc-collate=C \
              --lc-ctype=C \
              "$database_name"
            exit 0
          fi

          printf '%s\n' "matrix-synapse database ${cfg.databaseName} exists with locale $database_locale and contains user tables; migrate it to LC_COLLATE C / LC_CTYPE C or drop it manually." >&2
          exit 1
        '';
    };

    tmpfiles.directories = [
      {
        target = cfg.stateDir;
        user = "matrix-synapse";
        group = "matrix-synapse";
        mode = "0750";
      }
    ];

    persist.storage.directories = [cfg.stateDir];

    systemd.services.matrix-synapse = {
      after = ["matrix-synapse-database.service"];
      requires = ["matrix-synapse-database.service"];
      # Persistent bind mounts can appear as root-owned before tmpfiles has
      # corrected them. Synapse generates its signing key in preStart, so fix
      # ownership before the upstream key-generation command runs.
      preStart = mkBefore ''
        install -dm750 -o matrix-synapse -g matrix-synapse ${cfg.stateDir}
      '';
    };

    # Create configured local accounts after Synapse is listening. Existing
    # accounts are left untouched: no password resets and no admin-flag drift
    # correction. This keeps rebuilds safe after users start using accounts.
    systemd.services.matrix-synapse-users = let
      helper = "${config.services.matrix-synapse.package}/bin/register_new_matrix_user";
      userScript =
        concatMapStringsSep "\n" (userName: let
          user = cfg.localUsers.${userName};
        in ''
          ensure_user ${lib.escapeShellArg userName} ${
            if user.admin
            then "1"
            else "0"
          }
        '')
        localUserNames;
    in {
      description = "Create Matrix Synapse local users";
      after = ["matrix-synapse.service"];
      requires = ["matrix-synapse.service"];
      wantedBy = ["multi-user.target"];
      path = [config.services.postgresql.finalPackage config.services.matrix-synapse.package];
      serviceConfig = {
        Type = "oneshot";
        User = "matrix-synapse";
        Group = "matrix-synapse";
        RemainAfterExit = true;
      };
      script =
        # bash
        ''
          set -euo pipefail

          helper="$(command -v matrix-synapse-register_new_matrix_user || true)"
          if [[ -z "$helper" ]]; then
            helper=${lib.escapeShellArg helper}
          fi

          ensure_user() {
            local userName="$1"
            local isAdmin="$2"
            local matrixUser="@''${userName}:${hostName}"
            local passwordFile="${cfg.stateDir}/users/''${userName}.password"
            local exists

            exists="$(psql -v ON_ERROR_STOP=1 -h /run/postgresql -U ${cfg.databaseUser} -d ${cfg.databaseName} -tAc "SELECT EXISTS (SELECT 1 FROM users WHERE name = '$matrixUser');")"
            if [[ "$exists" == "t" ]]; then
              return 0
            fi

            if [[ ! -r "$passwordFile" ]]; then
              printf '%s\n' "matrix-synapse password file missing for ''${userName}" >&2
              exit 1
            fi

            password="$(<"$passwordFile")"

            if [[ "$isAdmin" == "1" ]]; then
              "$helper" -c ${cfg.secretsFile} http://127.0.0.1:${toString cfg.port} -u "$userName" -p "$password" -a
            else
              "$helper" -c ${cfg.secretsFile} http://127.0.0.1:${toString cfg.port} -u "$userName" -p "$password" --no-admin
            fi
          }

          ${userScript}
        '';
    };

    # A bare proxy name becomes matrix.<host>, which is private Blocky DNS plus
    # internal-CA HTTPS in this repo's Traefik module.
    services.traefik.proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";

    # Serve the Matrix client well-known document locally, then expose it
    # through Traefik on the exact path so Synapse still handles everything
    # else.
    services.nginx.enable = true;
    services.nginx.virtualHosts."matrix-well-known" = {
      listen = [
        {
          addr = "127.0.0.1";
          port = wellKnownPort;
        }
      ];

      extraConfig = ''
        location = /.well-known/matrix/client {
          default_type application/json;
          add_header Access-Control-Allow-Origin "*" always;
          return 200 '{"m.homeserver":{"base_url":"https://${hostName}"},"io.element.e2ee":{"force_disable":true}}';
        }
      '';
    };

    services.traefik.dynamicConfigOptions.http = {
      routers."matrix-well-known" = {
        entrypoints = "websecure";
        rule = "Host(`${hostName}`) && Path(`/.well-known/matrix/client`)";
        priority = 1000;
        tls = {};
        middlewares = ["local"];
        service = "matrix-well-known";
      };

      services."matrix-well-known".loadBalancer.servers = [
        {
          url = "http://127.0.0.1:${toString wellKnownPort}";
        }
      ];
    };
  };
}
