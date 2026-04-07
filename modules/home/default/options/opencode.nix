# programs.opencode.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.opencode;

  # Base env variables for OpenCode
  baseEnv =
    pkgs.writeText "base.env"
    # sh
    ''
      # Path to OpenCode binary managed by npm
      OPENCODE_BIN="''${OPENCODE_BIN:-${config.home.sessionVariables.NPM_CONFIG_PREFIX}/bin/opencode}"
      OPENCODE_DIR="''${OPENCODE_DIR:-${config.home.homeDirectory}/${cfg.dataDir}}"

      # Enable native Exa-backed web search in OpenCode
      OPENCODE_ENABLE_EXA=1

      # Aliases to current model names
      MINIMAX_MODEL="minimax/MiniMax-M2.7"
      OPENAI_MODEL="openai/gpt-5.4"
      ANTHROPIC_MODEL="opencode/claude-opus-4-6"
      GOOGLE_MODEL="openrouter/google/gemini-3-pro-preview"
    '';

  # Encrypted API keys
  keysEnv =
    if cfg.apiKeys != null
    then "${config.age.secrets.opencode-env.path}"
    else "/dev/null";

  opencode-init = pkgs.self.mkScript {
    name = "opencode";
    path = [pkgs.git];
    text =
      # bash
      ''
        # Export environment variables
        set -a
        [[ -f "${baseEnv}" ]] && . "${baseEnv}"
        [[ -f "${keysEnv}" ]] && . "${keysEnv}"
        [[ -f "$OPENCODE_DIR/.env" ]] && . "$OPENCODE_DIR/.env"
        set +a

        # Initizalize OpenCode: install via npm
        opencode_init() {

          # Git clone OpenCode config repo into config directory
          mkdir -p $OPENCODE_DIR
          if [[ ! -d "$OPENCODE_DIR/.git" ]]; then
            git clone ${cfg.gitUrl} $OPENCODE_DIR
          fi

          # Ensure it was cloned before proceeding
          if [[ ! -d $OPENCODE_DIR/.git ]]; then
            echo "Failed to clone OpenCode configuration"
            exit 1
          fi

          # Install/update opencode globally
          # npm already enabled via toolchains.javascript.enable = true;
          npm i -g opencode-ai

          # Ensure OpenCode is actually installed
          if [[ ! -f $OPENCODE_BIN ]]; then
            echo "Failed to install OpenCode binary"
            exit 1
          fi

        }

        # If argument is "init", run the above script
        if [[ "''${@-}" == "init" ]]; then
          opencode_init

        # Else, if the config or binary is missing, run the above script first
        elif [[ ! -d "$OPENCODE_DIR/.git" ]] || [[ ! -e $OPENCODE_BIN ]]; then
          opencode_init
          $OPENCODE_BIN "$@"

        # Otherwise, just passthrough to opencode
        else
          $OPENCODE_BIN "$@"
        fi
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
    settings = filler;
    themes = filler;

    # Okay, here go:
    enable = lib.mkEnableOption "opencode";
    package = lib.mkOption {
      type = lib.types.package;
      default = opencode-init;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".config/opencode";
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
    gitUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/suderman/opencode";
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

    # Persist the config, data and state directories
    persist.storage.directories = [cfg.dataDir];
    persist.scratch.directories = [
      ".local/share/opencode"
      ".local/state/opencode"
    ];

    # Lazy typing
    home.shellAliases = rec {
      oc = "opencode";
      occ = "${oc} --continue";
    };

    # Add opencode wrapper to user path (higher priority than npm)
    home.file.".local/bin/opencode".source = "${cfg.package}/bin/opencode";

    # Let agenix know about any secrets set
    age.secrets = lib.mkIf (cfg.apiKeys != null) {
      opencode-env.rekeyFile = cfg.apiKeys;
    };

    # User service for OpenCode backend and web
    systemd.user.services.opencode = {
      Unit = {
        Description = "OpenCode Server";
        After = ["network-online.target" "agenix.service"];
        Requires = ["agenix.service"];
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
        in ["PATH=${lib.concatStringsSep ":" path}"];
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
    };
  };
}
