# services.honcho.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.services.honcho;
  inherit (lib) mkOption types;
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
      default = flake.inputs.honcho-src;
      defaultText = lib.literalExpression "flake.inputs.honcho-src";
      description = "Pinned Honcho source tree.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/honcho";
    };

    port = mkOption {
      type = types.port;
      default = 24880;
    };

    llm = {
      transport = mkOption {
        type = types.enum ["openai" "anthropic" "gemini"];
        default = "anthropic";
      };

      baseUrl = mkOption {
        type = types.str;
        default =
          if cfg.llm.transport == "anthropic"
          then "https://api.minimax.io/anthropic"
          else "https://api.minimax.io/v1";
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

      apiKeyEnv = mkOption {
        type = types.str;
        default = "HONCHO_EMBEDDING_API_KEY";
      };
    };

    redisPort = mkOption {
      type = types.port;
      default = 6379;
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

    age.secrets.honcho-env.rekeyFile = ./honcho-env.age;

    persist.storage.directories = [cfg.dataDir];

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = {
        url = "http://${cfg.host}:${toString cfg.port}";
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

      llmApiKeyEnv =
        if cfg.llm.transport == "anthropic"
        then "LLM_ANTHROPIC_API_KEY"
        else if cfg.llm.transport == "gemini"
        then "LLM_GEMINI_API_KEY"
        else "LLM_OPENAI_API_KEY";

      environment =
        {
          PYTHONUNBUFFERED = "1";
          PYTHON_DOTENV_DISABLED = "1";
          HOME = cfg.dataDir;
          UV_CACHE_DIR = "/var/cache/honcho/uv";
          UV_PROJECT_ENVIRONMENT = "${cfg.dataDir}/.venv";
          UV_PYTHON = lib.getExe python;
          UV_PYTHON_DOWNLOADS = "never";
          UV_LINK_MODE = "copy";
          LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;

          DB_CONNECTION_URI = "postgresql+psycopg:///honcho?host=/run/postgresql&user=honcho";

          LOG_LEVEL = "INFO";
          NAMESPACE = "honcho";
          VECTOR_STORE_TYPE = "pgvector";

          AUTH_USE_AUTH = "false";
          DERIVER_ENABLED = "true";
          DERIVER_WORKERS = "1";
          SUMMARY_ENABLED = "true";
          DREAM_ENABLED = "true";
          PEER_CARD_ENABLED = "true";
          METRICS_ENABLED = "false";

          DERIVER_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DERIVER_MODEL_CONFIG__MODEL = cfg.llm.model;
          DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DERIVER_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = llmApiKeyEnv;

          SUMMARY_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          SUMMARY_MODEL_CONFIG__MODEL = cfg.llm.model;
          SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          SUMMARY_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = llmApiKeyEnv;

          DREAM_DEDUCTION_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DREAM_DEDUCTION_MODEL_CONFIG__MODEL = cfg.llm.model;
          DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = llmApiKeyEnv;

          DREAM_INDUCTION_MODEL_CONFIG__TRANSPORT = cfg.llm.transport;
          DREAM_INDUCTION_MODEL_CONFIG__MODEL = cfg.llm.model;
          DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.llm.baseUrl;
          DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = llmApiKeyEnv;
        }
        // (
          builtins.foldl'
          (
            acc: level:
              acc
              // {
                "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__TRANSPORT" = cfg.llm.transport;
                "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__MODEL" = cfg.llm.model;
                "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__OVERRIDES__BASE_URL" = cfg.llm.baseUrl;
                "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__OVERRIDES__API_KEY_ENV" = llmApiKeyEnv;
              }
          )
          {}
          [
            "minimal"
            "low"
            "medium"
            "high"
            "max"
          ]
        )
        // {
          EMBED_MESSAGES = "true";
          EMBEDDING_MODEL_CONFIG__TRANSPORT = cfg.embeddings.transport;
          EMBEDDING_MODEL_CONFIG__MODEL = cfg.embeddings.model;
          EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL = cfg.embeddings.baseUrl;
          EMBEDDING_MODEL_CONFIG__OVERRIDES__API_KEY_ENV = cfg.embeddings.apiKeyEnv;

          CACHE_ENABLED = "true";
          CACHE_URL = "redis://127.0.0.1:${toString cfg.redisPort}/0?suppress=true";
        }
        // (
          if cfg.llm.transport == "openai"
          then {}
          else
            {
              DERIVER_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
              SUMMARY_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
              DREAM_DEDUCTION_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
              DREAM_INDUCTION_MODEL_CONFIG__THINKING_BUDGET_TOKENS = "0";
            }
            // (
              builtins.foldl'
              (acc: level: acc // {"DIALECTIC_LEVELS__${level}__MODEL_CONFIG__THINKING_BUDGET_TOKENS" = "0";})
              {}
              [
                "minimal"
                "low"
                "medium"
                "high"
                "max"
              ]
            )
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
        path =
          [
            pkgs.uv
            python
            config.services.postgresql.finalPackage
          ]
          ++ runtimeLibs;
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
        path =
          [
            pkgs.uv
            python
          ]
          ++ runtimeLibs;
        serviceConfig = mkServiceConfig {
          Restart = "on-failure";
          RestartSec = "5s";
        };
        script =
          # sh
          ''
            exec uv run --frozen --no-sync --no-group dev fastapi run --host ${lib.escapeShellArg cfg.host} --port ${toString cfg.port} src/main.py
          '';
      };

      honcho-deriver = {
        description = "Honcho background deriver";
        wantedBy = ["multi-user.target"];
        after = runtimeDeps;
        requires = runtimeDeps;
        inherit environment;
        path =
          [
            pkgs.uv
            python
          ]
          ++ runtimeLibs;
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
