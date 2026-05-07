# services.honcho.enable = true;
#
# Example host wiring:
#   services.honcho.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
let
  cfg = config.services.honcho;

  inherit (lib)
    concatLists
    genAttrs
    getExe
    literalExpression
    mapAttrs'
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkOverride
    nameValuePair
    optional
    optionalAttrs
    optionalString
    types
    ;

  python = pkgs.python313;

  dbConnectionUri =
    if cfg.database.connectionUri != null then
      cfg.database.connectionUri
    else
      "postgresql+psycopg:///${cfg.database.name}?host=/run/postgresql&user=${cfg.database.user}";

  commonEnv = {
    PYTHONUNBUFFERED = "1";
    PYTHON_DOTENV_DISABLED = "1";
    HOME = cfg.stateDir;
    UV_CACHE_DIR = "${cfg.cacheDir}/uv";
    UV_PROJECT_ENVIRONMENT = "${cfg.stateDir}/.venv";
    UV_PYTHON = getExe python;
    UV_PYTHON_DOWNLOADS = "never";

    DB_CONNECTION_URI = dbConnectionUri;

    LOG_LEVEL = cfg.logLevel;
    NAMESPACE = cfg.namespace;
    VECTOR_STORE_TYPE = "pgvector";

    AUTH_USE_AUTH = lib.boolToString cfg.auth.enable;
    DERIVER_ENABLED = lib.boolToString cfg.deriver.enable;
    DERIVER_WORKERS = toString cfg.deriver.workers;
    SUMMARY_ENABLED = lib.boolToString cfg.summary.enable;
    DREAM_ENABLED = lib.boolToString cfg.dream.enable;
    PEER_CARD_ENABLED = lib.boolToString cfg.peerCard.enable;
    METRICS_ENABLED = lib.boolToString cfg.metrics.enable;
  }
  // {
    DERIVER_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
    DERIVER_MODEL_CONFIG__MODEL = cfg.llm.model;
    DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
    DERIVER_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";

    SUMMARY_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
    SUMMARY_MODEL_CONFIG__MODEL = cfg.llm.model;
    SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
    SUMMARY_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";

    DREAM_DEDUCTION_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
    DREAM_DEDUCTION_MODEL_CONFIG__MODEL = cfg.llm.model;
    DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
    DREAM_DEDUCTION_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";

    DREAM_INDUCTION_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
    DREAM_INDUCTION_MODEL_CONFIG__MODEL = cfg.llm.model;
    DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
    DREAM_INDUCTION_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
  }
  // (builtins.foldl'
    (
      acc: level:
      acc
      // {
        "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__TRANSPORT" = cfg.llm.transport;
        "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__MODEL" = cfg.llm.model;
        "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__OVERRIDES__BASE_URL" = cfg.llm.baseUrl;
        "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__THINKING_BUDGET_TOKENS" = "0";
      }
    )
    { }
    [
      "minimal"
      "low"
      "medium"
      "high"
      "max"
    ]
  )
  // (
    if cfg.embeddings.enable then
      {
        EMBED_MESSAGES = "true";
        EMBEDDING_MODEL_CONFIG__TRANSPORT = cfg.embeddings.transport;
        EMBEDDING_MODEL_CONFIG__MODEL = cfg.embeddings.model;
        EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.embeddings.baseUrl;
        EMBEDDING_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.embeddings.apiKeyEnv;
        EMBEDDING_VECTOR_DIMENSIONS = toString cfg.embeddings.dimensions;
        VECTOR_STORE_DIMENSIONS = toString cfg.embeddings.dimensions;
      }
    else
      {
        EMBED_MESSAGES = "false";
      }
  )
  // (
    if cfg.redis.enable then
      {
        CACHE_ENABLED = "true";
        CACHE_URL = "redis://127.0.0.1:${toString cfg.redis.port}/0?suppress=true";
      }
    else
      {
        CACHE_ENABLED = "false";
      }
  )
  // cfg.extraEnvironment;

  commonServiceConfig = {
    User = cfg.user;
    Group = cfg.group;
    WorkingDirectory = cfg.source;
    StateDirectory = "honcho";
    CacheDirectory = "honcho";
    UMask = "0077";
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    NoNewPrivileges = true;
    ProtectControlGroups = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    RestrictAddressFamilies = [
      "AF_INET"
      "AF_INET6"
      "AF_UNIX"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    SystemCallArchitectures = "native";
    CapabilityBoundingSet = "";
    EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
  };

  postgresDeps =
    optional cfg.database.managePostgres "postgresql.service"
    ++ optional cfg.database.managePostgres "postgresql-setup.service"
    ++ optional cfg.database.managePostgres "honcho-postgresql.service";

  runtimeDeps =
    postgresDeps ++ [ "honcho-setup.service" ] ++ optional cfg.redis.enable "redis-honcho.service";
in
{
  options.services.honcho = {
    enable = mkEnableOption "Plastic Labs Honcho";

    source = mkOption {
      type = types.path;
      default = flake.inputs.honcho-src;
      defaultText = literalExpression "flake.inputs.honcho-src";
      description = "Pinned Honcho source tree.";
    };

    user = mkOption {
      type = types.str;
      default = "honcho";
    };

    group = mkOption {
      type = types.str;
      default = "honcho";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    port = mkOption {
      type = types.port;
      default = 24880;
    };

    environmentFile = mkOption {
      type = with types; nullOr path;
      default = config.age.secrets.honcho-env.path;
      example = literalExpression "config.age.secrets.honcho-env.path";
    };

    namespace = mkOption {
      type = types.str;
      default = "honcho";
    };

    logLevel = mkOption {
      type = types.str;
      default = "INFO";
    };

    name = mkOption {
      type = types.str;
      default = "honcho";
      description = "Traefik proxy name for Honcho.";
    };

    public = mkOption {
      type = types.bool;
      default = false;
      description = "Whether the Traefik router should be treated as public.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/honcho";
      readOnly = true;
    };

    cacheDir = mkOption {
      type = types.str;
      default = "/var/cache/honcho";
      readOnly = true;
    };

    llm = {
      transport = mkOption {
        type = types.enum [
          "openai"
          "anthropic"
          "gemini"
        ];
        default = "openai";
      };

      baseUrl = mkOption {
        type = types.str;
        default = "https://api.minimax.io/v1";
      };

      model = mkOption {
        type = types.str;
        default = "MiniMax-M2.7";
      };
    };

    embeddings = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };

      transport = mkOption {
        type = types.enum [
          "openai"
          "gemini"
        ];
        default = "openai";
      };

      baseUrl = mkOption {
        type = types.str;
        default = "https://openrouter.ai/api/v1";
      };

      model = mkOption {
        type = types.str;
        default = "openai/text-embedding-3-small";
      };

      dimensions = mkOption {
        type = types.ints.positive;
        default = 1536;
      };

      apiKeyEnv = mkOption {
        type = types.str;
        default = "HONCHO_EMBEDDING_API_KEY";
      };
    };

    database = {
      managePostgres = mkOption {
        type = types.bool;
        default = true;
      };

      package = mkOption {
        type = types.package;
        default = pkgs.postgresql_17;
        defaultText = literalExpression "pkgs.postgresql_17";
      };

      name = mkOption {
        type = types.str;
        default = "honcho";
      };

      user = mkOption {
        type = types.str;
        default = "honcho";
      };

      connectionUri = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "postgresql+psycopg://honcho:password@127.0.0.1:5432/honcho";
      };
    };

    redis = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };

      port = mkOption {
        type = types.port;
        default = 6379;
      };
    };

    deriver = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };

      workers = mkOption {
        type = types.ints.positive;
        default = 1;
      };
    };

    summary.enable = mkOption {
      type = types.bool;
      default = true;
    };

    dream.enable = mkOption {
      type = types.bool;
      default = true;
    };

    peerCard.enable = mkOption {
      type = types.bool;
      default = true;
    };

    auth.enable = mkOption {
      type = types.bool;
      default = false;
    };

    metrics.enable = mkOption {
      type = types.bool;
      default = false;
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFile != null;
        message = "services.honcho.environmentFile must point at a secret env file.";
      }
      {
        assertion = cfg.embeddings.dimensions == 1536;
        message = "Honcho pgvector deployments currently require 1536-dimensional embeddings.";
      }
      {
        assertion = cfg.database.connectionUri != null || cfg.user == cfg.database.user;
        message = ''
          services.honcho uses a local PostgreSQL socket by default.
          Keep services.honcho.user equal to services.honcho.database.user,
          or set services.honcho.database.connectionUri explicitly.
        '';
      }
    ];

    users.groups.${cfg.group} = { };
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.stateDir;
      createHome = false;
      extraGroups = [ "secrets" ];
    };

    age.secrets.honcho-env.rekeyFile = ./honcho-env.age;

    persist.storage.directories = [
      cfg.stateDir
      cfg.cacheDir
    ];

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = {
        url = "http://${cfg.host}:${toString cfg.port}";
        inherit (cfg) public;
      };
    };

    services.redis.servers.honcho = mkIf cfg.redis.enable {
      enable = true;
      bind = "127.0.0.1";
      inherit (cfg.redis) port;
    };

    services.postgresql = mkIf cfg.database.managePostgres {
      enable = true;
      package = mkOverride 900 (cfg.database.package.withPackages (ps: [ ps.pgvector ]));
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureDBOwnership = cfg.database.user == cfg.database.name;
        }
      ];
    };

    systemd.services.honcho-postgresql = mkIf cfg.database.managePostgres {
      description = "Prepare Honcho PostgreSQL database";
      after = [
        "postgresql.service"
        "postgresql-setup.service"
      ];
      requires = [
        "postgresql.service"
        "postgresql-setup.service"
      ];
      serviceConfig = {
        User = "postgres";
        Group = "postgres";
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ config.services.postgresql.finalPackage ];
      script = ''
        psql -d postgres -tAc 'ALTER DATABASE "${cfg.database.name}" OWNER TO "${cfg.database.user}";'
        psql -d "${cfg.database.name}" -tAc 'GRANT ALL PRIVILEGES ON SCHEMA public TO "${cfg.database.user}";'
        psql -d "${cfg.database.name}" -tAc 'CREATE EXTENSION IF NOT EXISTS vector;'
      '';
    };

    systemd.services.honcho-setup = {
      description = "Prepare Honcho virtualenv and database";
      wantedBy = [ "multi-user.target" ];
      after = postgresDeps;
      requires = postgresDeps;
      environment = commonEnv;
      path = [
        pkgs.uv
        python
      ]
      ++ optional cfg.database.managePostgres config.services.postgresql.finalPackage;
      serviceConfig = commonServiceConfig // {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        uv sync --frozen --no-group dev
        uv run --frozen --no-sync --no-group dev python scripts/provision_db.py
      '';
    };

    systemd.services.honcho-api = {
      description = "Honcho API";
      wantedBy = [ "multi-user.target" ];
      after = runtimeDeps;
      requires = runtimeDeps;
      environment = commonEnv;
      path = [
        pkgs.uv
        python
      ];
      serviceConfig = commonServiceConfig // {
        Restart = "on-failure";
        RestartSec = "5s";
      };
      script = ''
        exec uv run --frozen --no-sync --no-group dev fastapi run --host ${lib.escapeShellArg cfg.host} --port ${toString cfg.port} src/main.py
      '';
    };

    systemd.services.honcho-deriver = mkIf cfg.deriver.enable {
      description = "Honcho background deriver";
      wantedBy = [ "multi-user.target" ];
      after = runtimeDeps;
      requires = runtimeDeps;
      environment = commonEnv;
      path = [
        pkgs.uv
        python
      ];
      serviceConfig = commonServiceConfig // {
        Restart = "on-failure";
        RestartSec = "5s";
      };
      script = ''
        exec uv run --frozen --no-sync --no-group dev python -m src.deriver
      '';
    };
  };
}
