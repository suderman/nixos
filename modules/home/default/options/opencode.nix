# programs.opencode.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.opencode;
  cfgDir = ".config/opencode";

  opencode-init = pkgs.self.mkScript {
    name = "opencode";
    path = [pkgs.coreutils];
    text =
      # bash
      ''
        OPENCODE_BIN="''${OPENCODE_BIN:-${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/opencode}"
        OPENCODE_DIR="''${OPENCODE_DIR:-${config.home.homeDirectory}/${cfgDir}}"
        OPENCODE_INIT_STAMP="''${OPENCODE_INIT_STAMP:-${config.home.homeDirectory}/.local/state/opencode/init.timestamp}"
        OPENCODE_INIT_INTERVAL="$((24 * 60 * 60))"

        set -a
        [[ -f "$OPENCODE_DIR/.env" ]] && . "$OPENCODE_DIR/.env"
        [[ -f "$OPENCODE_DIR/.env.local" ]] && . "$OPENCODE_DIR/.env.local"
        set +a

        opencode_install() {
          npm i -g opencode-ai

          if [[ ! -x "$OPENCODE_BIN" ]]; then
            echo "Failed to install OpenCode binary" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$OPENCODE_INIT_STAMP")"
          date +%s >"$OPENCODE_INIT_STAMP"
        }

        opencode_install_stale() {
          [[ ! -f "$OPENCODE_INIT_STAMP" ]] && return 0

          local now last
          now="$(date +%s)"
          last="$(<"$OPENCODE_INIT_STAMP")"

          [[ ! "$last" =~ ^[0-9]+$ ]] && return 0
          ((now - last >= OPENCODE_INIT_INTERVAL))
        }

        if [[ $# -eq 1 && "$1" == init ]]; then
          opencode_install
          exit
        fi

        if [[ ! -x "$OPENCODE_BIN" ]] || opencode_install_stale; then
          opencode_install
        fi

        exec "$OPENCODE_BIN" "$@"
      '';
  };
in {
  # Disable the home-manager opencode module so we can just make our own
  disabledModules = ["programs/opencode.nix"];
  options.programs.opencode = let
    filler = lib.mkOption {
      type = lib.types.anything;
      default = {};
    };
  in {
    # required by other modules so they don't complain
    tui = filler;
    settings = filler;
    themes = filler;

    # Okay, here go:
    enable = lib.mkEnableOption "opencode";
    package = lib.mkOption {
      type = lib.types.package;
      default = opencode-init;
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "opencode-${config.home.username}";
      example = "opencode-jon";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 4090 + config.home.portOffset; # automatically derived
      example = 4090;
      description = "Port number to run the OpenCode server";
    };
    apiKeys = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to multi-line .env file with API_KEY=123";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install OpenCode from npm and run with nodejs
    toolchains.javascript.enable = true;

    # Persist the writable config, data, and state directories.
    persist.storage.directories = [cfgDir];
    persist.scratch.directories = [
      ".local/share/opencode"
      ".local/state/opencode"
    ];

    home.activation.openCodeAgentConfiguration = lib.hm.dag.entryAfter ["agentConfigurationCheckout"] ''
      $DRY_RUN_CMD env \
        PATH=${lib.makeBinPath [pkgs.bash pkgs.coreutils]}:$PATH \
        OPENCODE_CONFIG_DIR=${config.home.homeDirectory}/${cfgDir} \
        XDG_STATE_HOME=${config.home.homeDirectory}/.local/state \
        ${config.home.homeDirectory}/.agents/opencode/bootstrap
    '';

    # Lazy typing
    home.shellAliases = rec {
      oc = "opencode";
      occ = "${oc} --continue";
      ocr = "${oc} run";
    };

    # Add opencode wrapper to user path (higher priority than npm)
    home.file.".local/bin/opencode".source = "${cfg.package}/bin/opencode";

    # Let agenix know about any secrets set
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      opencode-env.rekeyFile = cfg.apiKeys;
    };

    # Place .env in ~/.config/opencode
    systemd.user.services.opencode-env = let
      baseEnv = pkgs.writeText "opencode-base.env" ''
        # Enable native Exa-backed web search in OpenCode
        OPENCODE_ENABLE_EXA=1

        # API keys
      '';

      # Encrypted API keys
      # MINIMAX_API_KEY=
      # OPENCODE_API_KEY=
      # OPENROUTER_API_KEY=
      # CONTEXT7_API_KEY=
      keysEnv =
        if cfg.apiKeys != null
        then config.age.secrets.opencode-env.path
        else "/dev/null";
    in {
      Unit = {
        Description = "Generate OpenCode .env";
        Requires = lib.mkIf (cfg.apiKeys != null) ["agenix.service"];
        After = lib.mkIf (cfg.apiKeys != null) ["agenix.service"];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.self.mkScript {
          text =
            # sh
            ''
              OPENCODE_DIR="${config.home.homeDirectory}/${cfgDir}"
              DOTENV="$OPENCODE_DIR/.env"

              mkdir -p "$OPENCODE_DIR"

              tmp="$(mktemp "$OPENCODE_DIR/.env.tmp.XXXXXX")"
              cat ${baseEnv} > "$tmp"

              if [ -r "${keysEnv}" ]; then
                cat "${keysEnv}" >> "$tmp"
              ${lib.optionalString (cfg.apiKeys != null) ''
                else
                  echo "Missing OpenCode agenix env file: ${keysEnv}" >&2
                  rm -f "$tmp"
                  exit 1
              ''}
              fi

              chmod 600 "$tmp"
              mv "$tmp" "$DOTENV"
            '';
        };
      };

      Install.WantedBy = ["default.target"];
    };

    # User service for OpenCode backend and web
    systemd.user.services.opencode = {
      Unit = {
        Description = "OpenCode Server";
        After = ["network-online.target" "opencode-env.service"];
        Requires = ["opencode-env.service"];
        Wants = ["network-online.target"];
      };

      Service = {
        Type = "simple";
        Environment = let
          path =
            # Additions to my path including ~/bin, ~/.local/bin and various toolchains
            config.home.sessionPath
            # Primary paths used by NixOS
            ++ [
              "${config.home.profileDirectory}/bin"
              "/run/current-system/sw/bin"
              "/usr/bin"
              "/bin"
            ];
        in [
          "PATH=${lib.concatStringsSep ":" path}"
          "NPM_CONFIG_PREFIX=${config.home.sessionVariables.NPM_CONFIG_PREFIX}"
          "NPM_CONFIG_CACHE=${config.home.sessionVariables.NPM_CONFIG_CACHE}"
          "XDG_CACHE_HOME=%h/.cache/opencode-serve" # give the service a separate cache
        ];
        ExecStart = toString [
          "${cfg.package}/bin/opencode serve"
          "--port ${toString cfg.port}"
          "--cors ${cfg.name}.${config.networking.hostName}"
        ];
        Restart = "always";
        RestartSec = 5;
        TimeoutStopSec = 30;
        TimeoutStartSec = 30;
        SuccessExitStatus = "0 143";
        KillMode = "control-group";

        # Hardening
        # Keep the service able to write to repos outside $HOME, such as
        # /etc/nixos, so interactive coding sessions can use git normally.
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = false;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = false;
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
