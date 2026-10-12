# services.postgresql.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.postgresql;
  admins = config.users.groups.wheel.members ++ ["root"];
  databases = genAttrs (unique config.services.postgresql.ensureDatabases) (_database: admins);
  # databases = genAttrs admins (_database: admins);
  inherit (config.services.prometheus) exporters;
  inherit
    (lib)
    concatLines
    concatStringsSep
    escapeShellArg
    escapeShellArgs
    flatten
    genAttrs
    mapAttrsToList
    mkAfter
    mkIf
    mkOrder
    mkOverride
    optional
    optionalString
    toList
    unique
    versionOlder
    ;

  psql = "${config.services.postgresql.package}/bin/psql";

  sql = unique (
    flatten (
      mapAttrsToList (
        database: admins: (
          [
            # Grant all privileges for this database to the database user
            "${psql} -d \"${database}\" -tAc 'GRANT ALL PRIVILEGES ON SCHEMA public TO \"${database}\";'"
          ]
          ++ (map (
              admin:
              # Grant all privileges for this database to each admin user
              "${psql} -d \"${database}\" -tAc 'GRANT ALL PRIVILEGES ON SCHEMA public TO \"${admin}\";'"
            )
            admins)
        )
      )
      databases
    )
  );
in {
  config = mkIf cfg.enable {
    services.postgresql = {
      # 14 was default package as of 22.11
      # 15 was default package as of 23.11
      # 15 was default package as of 24.05
      # 16 was default package as of 24.11
      # 17 is default package as of 25.05
      # Hosts move to 18 one at a time with upgrade-pg-cluster. Upstream sets
      # its own mkDefault, so this sits between that and a plain host value.
      package = mkOverride 900 pkgs.postgresql_14;

      # Database & role for each admin
      ensureDatabases = admins;
      ensureUsers =
        map (name: {
          inherit name;
          ensureDBOwnership = true;
        })
        admins;

      # Allow password-less access on 127.0.0.1
      authentication = mkOrder 600 ''
        host all all 127.0.0.1/32 ident
      '';
    };

    # Ensure privileges for all database users and admins after setup has
    # created the databases and roles.
    systemd.services.postgresql-setup.script = mkAfter (concatLines sql);

    # ident is equivalent to peer, but requires identd daemon
    services.oidentd.enable = true;

    # Persist the data directory
    persist.storage.directories = ["/var/lib/postgresql"];

    # Containers bind-mount /run/postgresql for the socket. Keep the directory
    # when postgresql stops so those mounts still see the socket after restart.
    systemd.services.postgresql.serviceConfig.RuntimeDirectoryPreserve = "yes";

    # Copy this host's cluster into a new PostgreSQL 18 cluster, then set
    # services.postgresql.package = pkgs.postgresql_18 for the host and deploy.
    # The old cluster is left untouched for rollback.
    environment.systemPackages = optional (versionOlder cfg.package.version "18") (
      let
        new = pkgs.postgresql_18.withPackages cfg.extensions;
        preload = cfg.settings.shared_preload_libraries or null;
        preloadOptions = optionalString (preload != null) (
          let
            option = escapeShellArg "-c shared_preload_libraries=${concatStringsSep "," (toList preload)}";
          in "--old-options=${option} --new-options=${option}"
        );
      in
        pkgs.self.mkScript {
          name = "upgrade-pg-cluster";
          path = [pkgs.util-linux];
          env.LOCALE_ARCHIVE = "${config.i18n.glibcLocales}/lib/locale/locale-archive";
          text =
            # bash
            ''
              if [ "$(id -u)" != "0" ]; then
                echo "Run as root." >&2
                exit 1
              fi

              old_data=${cfg.dataDir}
              new_data=/var/lib/postgresql/${new.psqlSchema}
              if [ -e "$new_data/PG_VERSION" ]; then
                echo "$new_data already holds a cluster; remove it to retry." >&2
                exit 1
              fi

              # The new cluster must match the old encoding and locale
              read -r encoding collate ctype < <(
                runuser -u postgres -- ${cfg.finalPackage}/bin/psql -AtF ' ' -c \
                  "select pg_encoding_to_char(encoding), datcollate, datctype from pg_database where datname = 'template1'"
              )

              systemctl stop postgresql.service
              install -d -m 0700 -o postgres -g postgres "$new_data"
              cd "$new_data"

              # Old clusters have checksums off, which 18 enables by default
              runuser -u postgres -- ${new}/bin/initdb -D "$new_data" --no-data-checksums \
                --encoding="$encoding" --locale="$ctype" --lc-collate="$collate" ${escapeShellArgs cfg.initdbArgs}

              runuser -u postgres -- ${new}/bin/pg_upgrade \
                --old-datadir="$old_data" --new-datadir="$new_data" \
                --old-bindir=${cfg.finalPackage}/bin --new-bindir=${new}/bin \
                ${preloadOptions} "$@"

              echo "Upgraded. Set services.postgresql.package = pkgs.postgresql_18 for this host and deploy."
            '';
        }
    );

    # Metrics
    services.prometheus = {
      exporters.postgres = {
        enable = true;
        runAsLocalSuperUser = true;
      };
      scrapeConfigs = [
        {
          job_name = "postgresql";
          static_configs = [
            {targets = ["127.0.0.1:${toString exporters.postgres.port}"];}
          ];
        }
      ];
    };
  };
}
