# services.honcho.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.honcho;
  inherit (lib) mkOption types;

  # https://github.com/plastic-labs/honcho
  # last checked 2026-05-06
  honchoSrc = pkgs.fetchFromGitHub {
    owner = "plastic-labs";
    repo = "honcho";
    rev = "a4ae372932b064d8b9bdcf2d6a2c4faec4169162";
    hash = "sha256-zcfhg+q3eleHoyZBUnDRB4uxbJLMcT21wh7TRbHZVFE=";
  };
in {
  options.services.honcho = {
    enable = lib.mkEnableOption "Plastic Labs Honcho";

    name = mkOption {
      type = types.str;
      default = "honcho";
      description = "Traefik proxy name for Honcho.";
    };

    source = mkOption {
      type = types.path;
      default = "${honchoSrc}";
      description = "Pinned Honcho source tree.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/honcho";
    };

    port = mkOption {
      type = types.port;
      default = 24880;
    };

    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to multi-line .env file with API_KEY=123";
    };

    llm = {
      transport = mkOption {
        type = types.enum ["openai" "anthropic" "gemini"];
        default =
          if lib.hasSuffix "/anthropic" cfg.llm.baseUrl
          then "anthropic"
          else if lib.hasSuffix "/api/v1" cfg.llm.baseUrl
          then "openai"
          else "gemini";
      };

      baseUrl = mkOption {
        type = types.str;
        default = "https://api.minimax.io/anthropic";
      };

      model = mkOption {
        type = types.str;
        default = "MiniMax-M2.7";
      };

      apiKeyEnv = mkOption {
        type = types.str;
        default = "MINIMAX_API_KEY";
      };
    };

    embeddings = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };

      transport = mkOption {
        type = types.enum ["openai" "gemini"];
        default =
          if lib.hasSuffix "/api/v1" cfg.embeddings.baseUrl
          then "openai"
          else "gemini";
      };

      baseUrl = mkOption {
        type = types.str;
        default = "https://openrouter.ai/api/v1";
      };

      model = mkOption {
        type = types.str;
        default = "openai/text-embedding-3-small";
      };

      apiKeyEnv = mkOption {
        type = types.str;
        default = "OPENROUTER_API_KEY";
      };
    };

    # derive unique default redis port from cfg.name
    redisPort = mkOption {
      type = types.port;
      default = let
        base = 6380;
        span = 100;
        op = acc: char: lib.mod ((acc * 33) + lib.strings.charToInt char) span;
        chars = lib.strings.stringToCharacters "${toString base}:${cfg.name}";
      in
        base + (builtins.foldl' op 5381 chars);
    };
  };

  config = lib.mkIf cfg.enable {
    tmpfiles.directories = [
      {
        target = cfg.dataDir;
        mode = 750;
        user = "honcho";
      }
      {
        target = "/var/cache/honcho";
        user = "honcho";
      }
    ];

    users.groups.honcho = {};
    users.users.honcho = {
      isSystemUser = true;
      group = "honcho";
      home = cfg.dataDir;
      createHome = false;
      extraGroups = ["secrets"];
    };

    # Let agenix know about any secrets set
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      honcho-env.rekeyFile = cfg.apiKeys;
    };

    persist.storage.directories = [cfg.dataDir];

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = {
        url = "http://127.0.0.1:${toString cfg.port}";
      };
    };

    services.redis.servers."honcho" = {
      enable = true;
      bind = "127.0.0.1";
      port = cfg.redisPort;
    };

    services.postgresql = {
      enable = true;
      extensions = ps: [ps.pgvector];
      ensureDatabases = ["honcho"];
      ensureUsers = [
        {
          name = "honcho";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services = let
      python = pkgs.python313;
      runtimeLibs = [pkgs.stdenv.cc.cc];
      postgresDeps = ["postgresql.service" "postgresql-setup.service" "honcho-postgresql.service"];
      runtimeDeps = postgresDeps ++ ["honcho-setup.service" "redis-honcho.service"];

      environment =
        {
          # Python
          PYTHONUNBUFFERED = "1";
          PYTHON_DOTENV_DISABLED = "1";
          UV_CACHE_DIR = "/var/cache/honcho/uv";
          UV_PROJECT_ENVIRONMENT = "${cfg.dataDir}/.venv";
          UV_PYTHON = lib.getExe python;
          UV_PYTHON_DOWNLOADS = "never";
          UV_LINK_MODE = "copy";
          LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;

          # App
          HOME = cfg.dataDir;
          NAMESPACE = "honcho";
          LOG_LEVEL = "INFO";
          AUTH_USE_AUTH = "false";
          METRICS_ENABLED = "false";

          # Connection URI for PostgreSQL database with pgvector support
          # Must use postgresql+psycopg prefix for SQLAlchemy compatibility
          DB_CONNECTION_URI = "postgresql+psycopg:///honcho?host=/run/postgresql&user=honcho";
          VECTOR_STORE_TYPE = "pgvector";

          # Redis cache
          CACHE_ENABLED = "true";
          CACHE_URL = "redis://127.0.0.1:${toString cfg.redisPort}/0?suppress=true";

          # Embedding
          EMBED_MESSAGES = "true";
          EMBEDDING_MODEL_CONFIG__TRANSPORT = cfg.embeddings.transport;
          EMBEDDING_MODEL_CONFIG__MODEL = cfg.embeddings.model;
          EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.embeddings.baseUrl;
          EMBEDDING_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.embeddings.apiKeyEnv;

          # Deriver (background worker)
          DERIVER_ENABLED = "true";
          DERIVER_WORKERS = "1";
          DERIVER_FLUSH_ENABLED = "true";
          DERIVER_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DERIVER_MODEL_CONFIG__MODEL = cfg.llm.model;
          DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DERIVER_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;

          # Peer Card
          PEER_CARD_ENABLED = "true";

          # Summary
          SUMMARY_ENABLED = "true";
          SUMMARY_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          SUMMARY_MODEL_CONFIG__MODEL = cfg.llm.model;
          SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          SUMMARY_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;

          # Dream
          DREAM_ENABLED = "true";
          DREAM_SURPRISAL__ENABLED = "true";
          DREAM_IDLE_TIMEOUT_MINUTES = "30";
          DREAM_MIN_HOURS_BETWEEN_DREAMS = "4";

          # Dream (deduction)
          DREAM_DEDUCTION_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DREAM_DEDUCTION_MODEL_CONFIG__MODEL = cfg.llm.model;
          DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;

          # Dream (induction)
          DREAM_INDUCTION_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DREAM_INDUCTION_MODEL_CONFIG__MODEL = cfg.llm.model;
          DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;

          # Dialectic (minimal)
          DIALECTIC_LEVELS__minimal__MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DIALECTIC_LEVELS__minimal__MODEL_CONFIG__MODEL = cfg.llm.model;
          DIALECTIC_LEVELS__minimal__MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DIALECTIC_LEVELS__minimal__MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;

          # Dialectic (low)
          DIALECTIC_LEVELS__low__MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DIALECTIC_LEVELS__low__MODEL_CONFIG__MODEL = cfg.llm.model;
          DIALECTIC_LEVELS__low__MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DIALECTIC_LEVELS__low__MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;

          # Dialectic (medium)
          DIALECTIC_LEVELS__medium__MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DIALECTIC_LEVELS__medium__MODEL_CONFIG__MODEL = cfg.llm.model;
          DIALECTIC_LEVELS__medium__MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DIALECTIC_LEVELS__medium__MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;

          # Dialectic (high)
          DIALECTIC_LEVELS__high__MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DIALECTIC_LEVELS__high__MODEL_CONFIG__MODEL = cfg.llm.model;
          DIALECTIC_LEVELS__high__MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DIALECTIC_LEVELS__high__MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;

          # Dialectic (max)
          DIALECTIC_LEVELS__max__MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DIALECTIC_LEVELS__max__MODEL_CONFIG__MODEL = cfg.llm.model;
          DIALECTIC_LEVELS__max__MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DIALECTIC_LEVELS__max__MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.llm.apiKeyEnv;
        }
        # Thinking config depends on transport
        // (
          if cfg.llm.transport == "openai"
          then {
            DERIVER_MODEL_CONFIG__THINKING_EFFORT = "minimal";
            SUMMARY_MODEL_CONFIG__THINKING_EFFORT = "minimal";
            DREAM_DEDUCTION_MODEL_CONFIG__THINKING_EFFORT = "minimal";
            DREAM_INDUCTION_MODEL_CONFIG__THINKING_EFFORT = "minimal";
            DIALECTIC_LEVELS__minimal__MODEL_CONFIG__THINKING_EFFORT = "minimal";
            DIALECTIC_LEVELS__low__MODEL_CONFIG__THINKING_EFFORT = "minimal";
            DIALECTIC_LEVELS__medium__MODEL_CONFIG__THINKING_EFFORT = "minimal";
            DIALECTIC_LEVELS__high__MODEL_CONFIG__THINKING_EFFORT = "minimal";
            DIALECTIC_LEVELS__max__MODEL_CONFIG__THINKING_EFFORT = "minimal";
          }
          else {
            DERIVER_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            SUMMARY_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            DREAM_DEDUCTION_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            DREAM_INDUCTION_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            DIALECTIC_LEVELS__minimal__MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            DIALECTIC_LEVELS__low__MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            DIALECTIC_LEVELS__medium__MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            DIALECTIC_LEVELS__high__MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            DIALECTIC_LEVELS__max__MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
          }
        );

      mkServiceConfig = extraConfig:
        {
          User = "honcho";
          Group = "honcho";
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
          EnvironmentFile = config.age.secrets.honcho-env.path;
        }
        // extraConfig;
    in {
      honcho-postgresql = {
        description = "Prepare Honcho PostgreSQL database";
        after = ["postgresql.service" "postgresql-setup.service"];
        requires = ["postgresql.service" "postgresql-setup.service"];
        serviceConfig = {
          User = "postgres";
          Group = "postgres";
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [config.services.postgresql.finalPackage];
        script =
          # sh
          ''
            psql -d postgres -tAc 'ALTER DATABASE "honcho" OWNER TO "honcho";'
            psql -d "honcho" -tAc 'GRANT ALL PRIVILEGES ON SCHEMA public TO "honcho";'
            psql -d "honcho" -tAc 'CREATE EXTENSION IF NOT EXISTS vector;'
          '';
      };

      honcho-setup = {
        description = "Prepare Honcho virtualenv and database";
        wantedBy = ["multi-user.target"];
        after = postgresDeps;
        requires = postgresDeps;
        inherit environment;
        path = [pkgs.uv python config.services.postgresql.finalPackage] ++ runtimeLibs;
        serviceConfig = mkServiceConfig {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script =
          # sh
          ''
            uv sync --frozen --no-group dev
            uv run --frozen --no-sync --no-group dev python scripts/provision_db.py
          '';
      };

      honcho-api = {
        description = "Honcho API";
        wantedBy = ["multi-user.target"];
        after = runtimeDeps;
        requires = runtimeDeps;
        inherit environment;
        path = [pkgs.uv python] ++ runtimeLibs;
        serviceConfig = mkServiceConfig {
          Restart = "on-failure";
          RestartSec = "5s";
        };
        script =
          # sh
          ''
            exec uv run --frozen --no-sync --no-group dev fastapi run --host 127.0.0.1 --port ${toString cfg.port} src/main.py
          '';
      };

      honcho-deriver = {
        description = "Honcho background deriver";
        wantedBy = ["multi-user.target"];
        after = runtimeDeps;
        requires = runtimeDeps;
        inherit environment;
        path = [pkgs.uv python] ++ runtimeLibs;
        serviceConfig = mkServiceConfig {
          Restart = "on-failure";
          RestartSec = "5s";
        };
        script =
          # sh
          ''
            exec uv run --frozen --no-sync --no-group dev python -m src.deriver
          '';
      };
    };
  };
}
