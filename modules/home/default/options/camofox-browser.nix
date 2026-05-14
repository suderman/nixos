{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.camofox-browser;

  derivePort = name: base: let
    op = acc: char: lib.mod ((acc * 33) + lib.strings.charToInt char) base;
    chars = lib.strings.stringToCharacters "${toString base}:${name}";
  in
    base + 1 + (builtins.foldl' op 5381 chars);

  deriveServicePort = service: profile: base: derivePort "${service}:${profile}" base;

  hermesProfiles =
    if config.services.hermes-agent.enable
    then config.lib.hermes-agent.gatewayAgents
    else [];
  hermesDataDir =
    if config.services.hermes-agent.enable
    then config.lib.hermes-agent.dataDir
    else "${config.home.homeDirectory}/.local/share/hermes";

  profiles = lib.unique (cfg.profiles ++ hermesProfiles);
  camofoxEnabled = cfg.enable && profiles != [];

  runFileFor = profile: kind: "${cfg.runDir}/camofox-${profile}-${kind}";
  shareDirFor = profile: "${config.home.homeDirectory}/${cfg.dataDir}/${profile}";
  cookiesDirFor = profile: "${shareDirFor profile}/cookies";
  profilesDirFor = profile: "${shareDirFor profile}/profiles";
  stateDirFor = profile: "${config.home.homeDirectory}/${cfg.stateDir}/${profile}";
  tracesDirFor = profile: "${stateDirFor profile}/traces";
  cacheDirFor = profile: "${config.home.homeDirectory}/${cfg.cacheDir}/${profile}";
  apiPortFor = profile: deriveServicePort "camofox" profile (cfg.apiBasePort + config.home.portOffset);
  vncPortFor = profile: deriveServicePort "camofox-vnc" profile (cfg.vncBasePort + config.home.portOffset);

  camofox-init = pkgs.self.mkScript {
    name = "camofox-browser";
    path = [pkgs.nodejs];
    text =
      # bash
      ''
        CAMOFOX_BIN="''${CAMOFOX_BIN:-${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/camofox-browser}"
        CAMOFOX_INIT_STAMP="''${CAMOFOX_INIT_STAMP:-${config.home.homeDirectory}/.local/state/camofox-browser/init.timestamp}"
        CAMOFOX_INIT_INTERVAL="$((24 * 60 * 60))"

        camofox_init() {
          npm i -g camofox-browser

          if [[ ! -f "$CAMOFOX_BIN" ]]; then
            echo "Failed to install camofox-browser binary" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$CAMOFOX_INIT_STAMP")"
          date +%s >"$CAMOFOX_INIT_STAMP"
        }

        camofox_init_stale() {
          [[ ! -f "$CAMOFOX_INIT_STAMP" ]] && return 0

          local now last
          now="$(date +%s)"
          last="$(<"$CAMOFOX_INIT_STAMP")"

          [[ ! "$last" =~ ^[0-9]+$ ]] && return 0
          ((now - last >= CAMOFOX_INIT_INTERVAL))
        }

        if [[ "''${1:-}" == "init" ]]; then
          camofox_init
          exit 0
        fi

        if [[ "''${1:-}" == "ensure" ]]; then
          if [[ ! -e "$CAMOFOX_BIN" ]] || camofox_init_stale; then
            camofox_init
          fi
          exit 0
        fi

        if [[ ! -e "$CAMOFOX_BIN" ]] || camofox_init_stale; then
          camofox_init
        fi

        exec "$CAMOFOX_BIN" "$@"
      '';
  };
in {
  options.services.camofox-browser = {
    enable = lib.mkEnableOption "camofox-browser";

    name = lib.mkOption {
      type = lib.types.str;
      default = "camofox";
      description = "Base Traefik/DNS name for Camofox routes.";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Wrapper package that installs and runs camofox-browser.";
    };

    profiles = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Profile names to run as separate Camofox service instances.";
    };

    apiBasePort = lib.mkOption {
      type = lib.types.port;
      default = 9377;
      description = "Base port namespace used to derive per-profile Camofox API ports.";
    };

    vncBasePort = lib.mkOption {
      type = lib.types.port;
      default = 6080;
      description = "Base port namespace used to derive per-profile Camofox noVNC ports.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".local/share/camofox-browser";
      description = "Base data directory for Camofox profile state.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = ".local/state/camofox-browser";
      description = "Base state directory for Camofox runtime state.";
    };

    cacheDir = lib.mkOption {
      type = lib.types.str;
      default = ".cache/camofox-browser";
      description = "Base cache directory for Camofox instances.";
    };

    runDir = lib.mkOption {
      type = lib.types.str;
      default = "/run/camofox/${toString config.home.uid}";
      description = "Runtime directory for derived Camofox secrets.";
    };

    enableVnc = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable virtual display support for Camofox.";
    };

    crashReports.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable upstream Camofox crash telemetry.";
    };
  };

  config = lib.mkIf camofoxEnabled {
    services.camofox-browser.package = lib.mkDefault camofox-init;
    toolchains.javascript.enable = true;
    persist.scratch.directories = [cfg.stateDir cfg.cacheDir];

    tmpfiles.directories =
      lib.concatMap (profile: [
        {
          target = "${cfg.dataDir}/${profile}";
          mode = 700;
        }
        {
          target = "${cfg.dataDir}/${profile}/cookies";
          mode = 700;
        }
        {
          target = "${cfg.dataDir}/${profile}/profiles";
          mode = 700;
        }
        {
          target = "${cfg.stateDir}/${profile}";
          mode = 700;
        }
        {
          target = "${cfg.stateDir}/${profile}/traces";
          mode = 700;
        }
        {
          target = "${cfg.cacheDir}/${profile}";
          mode = 700;
        }
      ])
      profiles;

    tmpfiles.files =
      map (profile: {
        target = lib.removePrefix "${config.home.homeDirectory}/" "${hermesDataDir}/${profile}/.env.camofox";
        mode = 600;
        text = ''
          CAMOFOX_URL=http://127.0.0.1:${toString (apiPortFor profile)}
          CAMOFOX_API_KEY_FILE=${runFileFor profile "api-key"}
          CAMOFOX_ACCESS_KEY_FILE=${runFileFor profile "access-key"}
          CAMOFOX_ADMIN_KEY_FILE=${runFileFor profile "admin-key"}
        '';
      })
      hermesProfiles;

    home.file.".local/bin/camofox-browser".source = "${cfg.package}/bin/camofox-browser";

    systemd.user.services =
      {
        camofox-browser-init = {
          Unit = {
            Description = "Install or refresh camofox-browser";
            Wants = ["network-online.target"];
            After = ["network-online.target"];
          };

          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${cfg.package}/bin/camofox-browser ensure";
          };

          Install.WantedBy = ["default.target"];
        };
      }
      // lib.listToAttrs (map (profile: let
        path = config.home.sessionPath ++ ["${config.home.profileDirectory}/bin" "/run/current-system/sw/bin" "/usr/bin" "/bin"];
        script = pkgs.self.mkScript {
          name = "camofox-${profile}";
          path = [pkgs.coreutils];
          text =
            # bash
            ''
              export CAMOFOX_HOST=127.0.0.1
              export CAMOFOX_PORT=${toString (apiPortFor profile)}
              export CAMOFOX_HEADLESS=${
                if cfg.enableVnc
                then "virtual"
                else "true"
              }
              export CAMOFOX_COOKIES_DIR='${cookiesDirFor profile}'
              export CAMOFOX_PROFILES_DIR='${profilesDirFor profile}'
              export CAMOFOX_TRACES_DIR='${tracesDirFor profile}'
              export CAMOFOX_CRASH_REPORT_ENABLED=${
                if cfg.crashReports.enable
                then "true"
                else "false"
              }
              export NODE_ENV=production

              ${lib.optionalString cfg.enableVnc ''
                export CAMOFOX_VNC_BASE_PORT=${toString (vncPortFor profile)}
                export CAMOFOX_VNC_HOST=127.0.0.1
              ''}

              if [[ -r '${runFileFor profile "admin-key"}' ]]; then
                export CAMOFOX_ADMIN_KEY="$(cat '${runFileFor profile "admin-key"}')"
              fi

              exec '${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/camofox-browser'
            '';
        };
      in
        lib.nameValuePair "camofox-${profile}" {
          Unit = {
            Description = "Camofox browser server for profile ${profile}";
            After = ["network-online.target" "camofox-browser-init.service"];
            Requires = ["camofox-browser-init.service"];
            Wants = ["network-online.target"];
          };

          Service = {
            Type = "simple";
            Environment = [
              "PATH=${lib.concatStringsSep ":" path}"
              "XDG_CACHE_HOME=${cacheDirFor profile}"
            ];
            ExecStart = "${script}/bin/camofox-${profile}";
            Restart = "always";
            RestartSec = 5;
            TimeoutStopSec = 30;
            TimeoutStartSec = 300;
            SuccessExitStatus = "0 143";
            KillMode = "control-group";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = false;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = false;
          };

          Install.WantedBy = ["default.target"];
        })
      profiles);
  };
}
