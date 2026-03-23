# programs.opencode.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.opencode;
  inherit (lib) mkIf;

  opencode-init = pkgs.self.mkScript {
    name = "opencode";
    text =
      # bash
      ''
        export OPENCODE_BIN="''${OPENCODE_BIN:-${config.home.homeDirectory}/.local/share/npm/bin/opencode}"

        # Initizalize OpenCode: install via npm
        opencode_init() {

          # Install/update opencode globally
          # npm already enabled via toolchains.javascript.enable = true;
          npm i -g opencode-ai

          # Ensure OpenCode is actually installed
          if [[ ! -f $OPENCODE_BIN ]]; then
            echo "Failed to install opencode"
            exit 1
          fi
        }

        # If argument is "init", run the above script
        if [[ "''${@-}" == "init" ]]; then
          opencode_init

        # Else, if the binary is missing, run the above script first
        elif [[ ! -e $OPENCODE_BIN ]]; then
          opencode_init
          $OPENCODE_BIN "$@"

        # Otherwise, just passthrough to opencode
        else
          $OPENCODE_BIN "$@"
        fi
      '';
  };
in {
  options.programs.opencode = {
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
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      OPENCODE_MODEL = "openai/gpt-5.4";
      OPENCODE_SUBAGENT_MODEL = "openai/gpt-5.4-mini";
    };

    home.shellAliases = rec {
      oc = "opencode";
      occ = "${oc} --continue";
    };

    age.secrets = {
      openrouter.rekeyFile = ./openrouter.age; # provider
      zen.rekeyFile = ./zen.age; # provider
      smithery.rekeyFile = ./smithery.age; # exa mpc
    };

    programs.opencode = {
      enableMcpIntegration = true;
      rules = ./AGENTS.md;
      package = opencode-init;
      settings = let
        file = path: "{file:${path}}";
        env = env: "{env:${env}}";
      in {
        autoshare = false;
        autoupdate = false;

        provider = {
          openrouter.options.apiKey = file config.age.secrets.openrouter.path;
          opencode.options.apiKey = file config.age.secrets.zen.path;
        };

        keybinds = {
          model_list = "ctrl+j";
          session_list = "ctrl+k";
          input_newline = "shift+return,alt+return";
          editor_open = "ctrl+o,<leader>e";
        };

        model = env "OPENCODE_MODEL";
        agent.general = {
          mode = "subagent";
          model = env "OPENCODE_SUBAGENT_MODEL";
        };
        agent.explore = {
          mode = "subagent";
          model = env "OPENCODE_SUBAGENT_MODEL";
        };
        permission.bash = {
          "curl" = "allow";
          "git commit" = "ask";
          "git push" = "ask";
          "nix eval" = "allow";
          "nixos-rebuild" = "deny";
        };
        mcp.gh_grep = {
          type = "remote";
          url = "https://mcp.grep.app";
        };
        mcp.exa = {
          type = "remote";
          url = "https://mcp.exa.ai/mcp?exaApiKey=${file config.age.secrets.smithery.path}";
          enabled = true;
        };
        mcp.context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
      };
    };

    xdg.configFile = {
      "opencode/agents".source = ./agents;
      "opencode/commands".source = ./commands;
      "opencode/skills".source = ./skills;
      # "opencode/tools".source = ./tools;
    };

    persist.scratch.directories = [
      ".local/share/opencode"
      ".local/state/opencode"
    ];

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

    # Install OpenCode from npm and run with nodejs
    toolchains.javascript.enable = true;
  };
}
