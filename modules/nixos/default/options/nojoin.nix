# services.nojoin.enable = true;
{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.services.nojoin;
  pin = flake.inputs.pins.default.github.nojoin;
  source = pkgs.fetchFromGitHub {
    inherit (pin) owner repo rev hash;
  };
  caBundle = "/etc/ssl/certs/ca-bundle.crt";
  containerCaBundle = "/etc/ssl/certs/nojoin-ca-bundle.crt";
  secretDir = "/run/nojoin";
  openaiEnabled = cfg.apiKeys != null && cfg.openai.baseUrl != null;
  secretSpecs = [
    {
      name = "FIRST_RUN_PASSWORD";
      salt = "nojoin:first-run-password";
    }
    {
      name = "DATA_ENCRYPTION_KEY";
      salt = "nojoin:data-encryption-key";
    }
    {
      name = "POSTGRES_PASSWORD";
      salt = "nojoin:postgres-password";
    }
    {
      name = "REDIS_PASSWORD";
      salt = "nojoin:redis-password";
    }
  ];
  composeOverride = pkgs.writeText "nojoin-compose.override.yml" ''
    services:
      db:
        image: ${pin.postgresImage}
        volumes: !override
          - ${cfg.dataDir}/postgres:/var/lib/postgresql
      redis:
        image: ${pin.redisImage}
        volumes: !override
          - ${cfg.dataDir}/redis:/data
      socket-proxy:
        image: ${pin.socketProxyImage}
      api:
        image: ${pin.apiImage}
        volumes: !override
          - ${cfg.dataDir}/data:/app/data
          - ${cfg.cacheDir}:/shared_model_cache:ro
      worker-gpu:
        image: ${pin.workerImage}
        devices:
          - nvidia.com/gpu=all
        deploy:
          resources:
            reservations:
              devices: !override []
        volumes: !override
          - ${cfg.dataDir}/data:/app/data
          - ${cfg.cacheDir}:/home/appuser/.cache
          - /sys/class/drm:/sys/class/drm:ro
      worker-cpu:
        image: ${pin.workerImage}
        volumes: !override
          - ${cfg.dataDir}/data:/app/data
          - ${cfg.cacheDir}:/home/appuser/.cache
          - /sys/class/drm:/sys/class/drm:ro
      worker-io:
        image: ${pin.workerIoImage}
        build: !reset null
        volumes: !override
          - ${cfg.dataDir}/data:/app/data
          - ${cfg.cacheDir}:/home/appuser/.cache
          - /sys/class/drm:/sys/class/drm:ro
      worker-parse:
        image: ${pin.workerIoImage}
        volumes: !override
          - ${cfg.dataDir}/data:/app/data
          - ${cfg.cacheDir}:/home/appuser/.cache
          - /sys/class/drm:/sys/class/drm:ro
      frontend:
        image: ${pin.frontendImage}
      nginx:
        image: ${pin.nginxImage}
        volumes: !override
          - ${source}/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
          - ${cfg.dataDir}/nginx:/etc/nginx/certs
          - ${source}/docker/init-ssl.sh:/docker-entrypoint.d/99-init-ssl.sh:ro
    volumes: !override {}
  '';
  openaiOverride = pkgs.writeText "nojoin-openai.override.yml" (
    if openaiEnabled
    then ''
      x-nojoin-openai-environment: &nojoin-openai-environment
        OPENAI_BASE_URL: ${builtins.toJSON cfg.openai.baseUrl}
        SSL_CERT_FILE: ${containerCaBundle}
        REQUESTS_CA_BUNDLE: ${containerCaBundle}

      x-nojoin-ca-volume: &nojoin-ca-volume
        - ${caBundle}:${containerCaBundle}:ro

      services:
        api:
          environment: *nojoin-openai-environment
          volumes: *nojoin-ca-volume
        worker-gpu:
          environment: *nojoin-openai-environment
          volumes: *nojoin-ca-volume
        worker-cpu:
          environment: *nojoin-openai-environment
          volumes: *nojoin-ca-volume
        worker-io:
          environment: *nojoin-openai-environment
          volumes: *nojoin-ca-volume
        worker-parse:
          environment: *nojoin-openai-environment
          volumes: *nojoin-ca-volume
    ''
    else ''
      services: {}
    ''
  );
  nojoinCompose = pkgs.writeShellApplication {
    name = "nojoin-compose";
    runtimeInputs = [pkgs.docker];
    text = ''
      set -a
      # shellcheck disable=SC1091
      source ${secretDir}/environment
      export WEB_APP_URL=${lib.escapeShellArg "https://${cfg.hostName}"}
      export NOJOIN_BIND_ADDRESS=127.0.0.1
      export NOJOIN_TRUSTED_PROXIES=127.0.0.1,::1,nginx,172.16.0.0/12
      export NOJOIN_TELEMETRY_ENABLED=false
      export DEFAULT_TIMEZONE=${lib.escapeShellArg config.time.timeZone}
      export NVIDIA_VISIBLE_DEVICES=all
      export NVIDIA_DRIVER_CAPABILITIES=compute,utility
      set +a
      ${lib.optionalString openaiEnabled ''
        api_key_env=${lib.escapeShellArg cfg.openai.apiKeyEnv}
        OPENAI_API_KEY="$(
          set +u
          # shellcheck disable=SC1091
          source ${lib.escapeShellArg config.age.secrets.nojoin-api-keys.path}
          printf '%s' "''${!api_key_env}"
        )"
        if [[ -z "$OPENAI_API_KEY" ]]; then
          echo "$api_key_env is missing from the Nojoin API key file" >&2
          exit 1
        fi
        export OPENAI_API_KEY
        export LLM_PROVIDER=openai
      ''}
      exec docker compose \
        --project-directory ${lib.escapeShellArg cfg.dataDir} \
        -f ${source}/docker-compose.example.yml \
        -f ${composeOverride} \
        -f ${openaiOverride} \
        "$@"
    '';
  };
in {
  options.services.nojoin = {
    enable = lib.mkEnableOption "Nojoin meeting assistant";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nojoin.${config.networking.hostName}";
      description = "Private HTTPS hostname for Nojoin.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/nojoin";
      description = "Directory for durable Nojoin, PostgreSQL, Redis, and TLS state.";
    };

    cacheDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/cache/nojoin";
      description = "Directory for the reproducible shared model cache.";
    };

    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Encrypted environment file containing the OpenAI-compatible API key.";
    };

    openai = {
      baseUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "OpenAI-compatible API base URL.";
      };

      apiKeyEnv = lib.mkOption {
        type = lib.types.str;
        default = "OPENAI_API_KEY";
        description = "Variable in apiKeys to expose to Nojoin as OPENAI_API_KEY.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.hardware.nvidia-container-toolkit.enable;
        message = "services.nojoin requires hardware.nvidia-container-toolkit.enable";
      }
      {
        assertion = (cfg.apiKeys == null) == (cfg.openai.baseUrl == null);
        message = "services.nojoin.apiKeys and services.nojoin.openai.baseUrl must be set together";
      }
      {
        assertion = builtins.match "[A-Za-z_][A-Za-z0-9_]*" cfg.openai.apiKeyEnv != null;
        message = "services.nojoin.openai.apiKeyEnv must be a valid environment variable name";
      }
    ];

    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      nojoin-api-keys.rekeyFile = cfg.apiKeys;
    };

    virtualisation.docker.enable = true;
    environment.systemPackages = [nojoinCompose];

    persist.storage.directories = [cfg.dataDir];
    persist.scratch.directories = [cfg.cacheDir];
    tmpfiles.directories = [
      {
        target = cfg.dataDir;
        mode = "0750";
      }
      {
        target = "${cfg.dataDir}/data";
        mode = "0750";
        user = "1000";
        group = "1000";
      }
      {
        target = "${cfg.dataDir}/postgres";
        # PostgreSQL 18 keeps PGDATA below this mount and needs to traverse it after dropping privileges.
        mode = "0711";
      }
      {
        target = "${cfg.dataDir}/redis";
        mode = "0700";
      }
      {
        target = "${cfg.dataDir}/nginx";
        mode = "0700";
      }
      {
        target = cfg.cacheDir;
        mode = "0750";
        user = "1000";
        group = "1000";
      }
    ];

    identityRotation.verificationCommands =
      lib.concatMapStringsSep "\n" (secret: ''
        verify_derived ${lib.escapeShellArg secret.salt} ${lib.escapeShellArg "${secretDir}/${secret.name}"} 32
      '')
      secretSpecs
      + ''
        systemctl is-active --quiet nojoin.service
      '';
    identityRotation.verificationUnits = ["nojoin.service"];

    system.activationScripts.nojoin-secrets = let
      inherit (perSystem.self) derive mkScript;
      hex = config.identityRotation.hexPath;
      writeSecret = secret: ''
        derive hex ${lib.escapeShellArg secret.salt} 32 <${hex} >"$tmp"
        install -m600 -o root -g root "$tmp" ${lib.escapeShellArg "${secretDir}/${secret.name}"}
      '';
      writeEnvironment = secret: ''
        printf '%s=%s\n' ${lib.escapeShellArg secret.name} "$(cat ${lib.escapeShellArg "${secretDir}/${secret.name}"})"
      '';
      text = ''
        if [[ -f ${hex} ]]; then
          install -dm700 -o root -g root ${secretDir}
          tmp="$(mktemp)"
          environment_tmp=""
          trap 'rm -f "$tmp" "$environment_tmp"' EXIT

          ${lib.concatMapStringsSep "\n" writeSecret secretSpecs}

          environment_tmp="$(mktemp)"
          {
            ${lib.concatMapStringsSep "\n" writeEnvironment secretSpecs}
          } >"$environment_tmp"
          install -m600 -o root -g root "$environment_tmp" ${secretDir}/environment
        fi
      '';
    in
      lib.mkAfter ''
        # Derive Nojoin secrets into tmpfs so they never enter the Nix store.
        ${mkScript {
          inherit text;
          path = [derive];
        }}
      '';

    systemd.services.nojoin = {
      description = "Nojoin Compose stack";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["docker.service" "network-online.target"];
      requires = ["docker.service"];
      restartTriggers = [config.identityRotation.hexPath composeOverride openaiOverride];
      unitConfig.RequiresMountsFor = [cfg.dataDir cfg.cacheDir];
      preStart = ''
        ${pkgs.coreutils}/bin/install -d -m 0750 -o 1000 -g 1000 ${lib.escapeShellArg cfg.cacheDir}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "30min";
        TimeoutStopSec = "5min";
        ExecStart = "${nojoinCompose}/bin/nojoin-compose up -d --remove-orphans --wait";
        ExecStop = "${nojoinCompose}/bin/nojoin-compose down";
      };
    };

    services.traefik = {
      enable = true;
      dynamicConfigOptions.http = {
        middlewares.nojoin-headers.headers.customRequestHeaders = {
          Host = cfg.hostName;
          X-Forwarded-Host = cfg.hostName;
          X-Forwarded-Proto = "https";
        };
        routers.nojoin = {
          entrypoints = "websecure";
          rule = "Host(`${cfg.hostName}`)";
          tls = {};
          middlewares = ["local" "nojoin-headers"];
          service = "nojoin";
        };
        services.nojoin.loadBalancer = {
          passHostHeader = true;
          serversTransport = "nojoin";
          servers = [{url = "https://127.0.0.1:14443";}];
        };
        serversTransports.nojoin.insecureSkipVerify = true;
      };
    };
  };
}
