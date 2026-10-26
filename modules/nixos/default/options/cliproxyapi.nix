# Copied from nixpkgs fe13242281a67641c0102cdb1087f0ebe586c7df.
# services.cliproxyapi.enable = true;
{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  cfg = config.services.cliproxyapi;
  format = pkgs.formats.yaml {};
  stateDir = "/var/lib/cliproxyapi";
  configPath = "${stateDir}/config.yaml";
  secretsReplacement =
    utils.genJqSecretsReplacement {
      loadCredential = true;
    }
    cfg.settings
    configPath;
in {
  disabledModules = ["services/misc/cliproxyapi.nix"];

  options.services.cliproxyapi = {
    enable = lib.mkEnableOption "CLIProxyAPI";

    package = lib.mkPackageOption pkgs.unstable "cliproxyapi" {};

    name = lib.mkOption {
      type = lib.types.str;
      default = "cliproxyapi";
      description = "Internal reverse-proxy hostname prefix.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type;
        options = {
          server.port = lib.mkOption {
            type = lib.types.port;
            default = 8317;
            description = "Port on which CLIProxyAPI listens.";
          };
          oauth.auth-dir = lib.mkOption {
            type = lib.types.str;
            default = stateDir;
            description = "Directory where OAuth tokens are stored.";
          };
        };
      };
      default = {};
      example = lib.literalExpression ''
        {
          server = {
            host = "127.0.0.1";
            port = 8317;
          };
          access.api-keys = [ { _secret = "/run/secrets/cliproxyapi-api-key"; } ];
          management.secret-key._secret = "/run/secrets/cliproxyapi-management-key";
        }
      '';
      description = ''
        Configuration for CLIProxyAPI. See the
        [example configuration](https://github.com/router-for-me/CLIProxyAPI/blob/main/config.example.yaml)
        for available options. Secret values can be loaded from files using
        `._secret = "/path/to/secret";`.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/cliproxyapi.env";
      description = "Environment file as defined in {manpage}`systemd.exec(5)`.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for {option}`services.cliproxyapi.settings.server.port`.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "cliproxyapi";
      description = "User account under which CLIProxyAPI runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "cliproxyapi";
      description = "Group under which CLIProxyAPI runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.cliproxyapi.settings = {
      server.host = lib.mkDefault "127.0.0.1";
      access.api-keys = lib.mkDefault [{_secret = "${stateDir}/api-key";}];
      management = {
        allow-remote = lib.mkDefault true;
        secret-key = lib.mkDefault {_secret = "${stateDir}/management-key";};
      };
      routing = {
        strategy = lib.mkDefault "round-robin";
        session-affinity = lib.mkDefault true;
        session-affinity-ttl = lib.mkDefault "30m";
        session-affinity-subagents = lib.mkDefault true;
        session-affinity-rebind-on = lib.mkDefault "quota";
        retry = {
          request-retry = lib.mkDefault 3;
          max-retry-credentials = lib.mkDefault 0;
          max-retry-interval = lib.mkDefault 30;
        };
        cooldown.save-cooldown-status = lib.mkDefault true;
      };
      requests.streaming = {
        keepalive-seconds = lib.mkDefault 15;
        bootstrap-retries = lib.mkDefault 1;
      };
      observability.usage.usage-statistics-enabled = lib.mkDefault true;
    };

    environment.systemPackages = [cfg.package];

    persist.storage.directories = [
      {
        directory = stateDir;
        user = cfg.user;
        group = cfg.group;
        mode = "0700";
      }
    ];

    services.traefik = {
      enable = true;
      proxy.${cfg.name} = {
        hostName = config.services.traefik.lib.mkHostName cfg.name;
        url = "http://127.0.0.1:${toString cfg.settings.server.port}";
        public = false;
      };
    };

    users.users = lib.mkIf (cfg.user == "cliproxyapi") {
      cliproxyapi = {
        isSystemUser = true;
        group = cfg.group;
        home = stateDir;
        description = "CLIProxyAPI service user";
      };
    };

    users.groups = lib.mkIf (cfg.group == "cliproxyapi") {
      cliproxyapi = {};
    };

    systemd.services.cliproxyapi = {
      description = "Proxy that provides OpenAI/Gemini/Claude/Codex/Grok compatible API interfaces";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      unitConfig.RequiresMountsFor = [stateDir];
      preStart = secretsReplacement.script;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "cliproxyapi";
        StateDirectoryMode = "0700";
        WorkingDirectory = stateDir;
        ExecStart = "${lib.getExe cfg.package} -config ${configPath}";
        Restart = "on-failure";
        RestartSec = 5;
        LoadCredential = secretsReplacement.credentials;
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) [cfg.environmentFile];

        # Hardening
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RemoveIPC = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        UMask = "0077";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.settings.server.port];
    };
  };

  meta = {
    maintainers = [lib.maintainers.anish];
  };
}
