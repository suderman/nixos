# config.programs.openclaw.enable = true;
{
  config,
  osConfig,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.openclaw;
  osCfg = osConfig.services.openclaw;
  inherit (lib) mkIf mkAfter;

  openclawEnv =
    # sh
    ''
      export OPENCLAW_GATEWAY_HOST=${cfg.host}
      export OPENCLAW_GATEWAY_PORT=${toString cfg.port}
      if [[ -f /run/openclaw/gateway ]]; then
        export OPENCLAW_GATEWAY_TOKEN=$(cat /run/openclaw/gateway)
      fi
    '';
in {
  options.programs.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.llm-agents.openclaw;
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "bot.kit";
      description = "Host running the OpenClaw gateway";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "Port the OpenClaw gateway is listening to";
    };
  };
  config =
    (mkIf cfg.enable {
      home.packages = [cfg.package];

      programs = {
        bash.profileExtra = lib.mkAfter openclawEnv;
        zsh.envExtra = lib.mkAfter openclawEnv;

        zsh.initContent =
          mkAfter
          # sh
          ''
            # OpenClaw completions (generate once, async)
            _openclaw_comp="$ZDOTDIR/openclaw"

            if [[ -r "$_openclaw_comp" ]]; then
              source "$_openclaw_comp"
            else
              {
                openclaw completion --shell zsh >| "$_openclaw_comp" 2>/dev/null
              } &!
            fi
          '';
      };
    })
    // (mkIf (osCfg.enable && osCfg.username == config.home.username) {
      persist.storage.directories = [osCfg.dataDir];

      systemd.user.services.openclaw-env = {
        Unit = {
          Description = "OpenClaw Prepare Gateway Environment";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
        };
        Service = {
          Type = "oneshot";

          ExecStart = perSystem.self.mkScript {
            text =
              # bash
              ''
                cat >/run/openclaw/gateway.env <<EOF
                OPENCLAW_GATEWAY_TOKEN=$(cat /run/openclaw/gateway)
                EOF
              '';
          };

          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = ["default.target"];
      };

      systemd.user.services.openclaw-gateway = {
        Unit = {
          Description = "OpenClaw Gateway";
          After = ["network-online.target" "openclaw-env"];
          Wants = ["network-online.target" "openclaw-env"];
        };

        Service = {
          Type = "simple";

          EnvironmentFile = "/run/openclaw/gateway.env";
          Environment = [
            "OPENCLAW_STATE_DIR=${config.home.homeDirectory}/${osCfg.dataDir}"
            "OPENCLAW_GATEWAY_PORT=${toString cfg.port}"
          ];

          ExecStart = "${cfg.package}/bin/openclaw gateway";

          Restart = "on-failure";
          RestartSec = 2;

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

      programs = {
        # openclaw = {
        #   enable = true;
        #   host = "${osCfg.username}.${config.networking.hostName}";
        #   port = 443;
        #   package = cfg.package;
        # };

        javascript.enable = true;
        python.enable = true;
      };
    });
}
# # config.programs.openclaw.enable = true;
# {
#   config,
#   lib,
#   perSystem,
#   pkgs,
#   ...
# }: let
#   cfg = config.programs.openclaw;
#   inherit (lib) mkIf mkAfter options;
#   dataDir = ".openclaw"; # default config & state directory for OpenClaw
# in {
#   options.programs.openclaw = {
#     enable = lib.mkEnableOption "openclaw";
#     package = lib.mkOption {
#       type = lib.types.package;
#       default = perSystem.llm-agents.openclaw;
#     };
#     host = lib.mkOption {
#       type = lib.types.str;
#       default = "127.0.0.1";
#       example = "bot.kit";
#       description = "Host running the OpenClaw gateway";
#     };
#     port = lib.mkOption {
#       type = lib.types.port;
#       default = 18789;
#       description = "Port the OpenClaw gateway is listening to";
#     };
#     seed = lib.mkOption {
#       type = lib.types.str;
#       default = "";
#       example = "bot";
#       description = "Seed word used to derive the OPENCLAW_GATEWAY_TOKEN";
#     };
#   };
#   config = mkIf cfg.enable ({
#       home.sessionVariables = {
#         OPENCLAW_STATE_DIR = "${config.home.homeDirectory}/${dataDir}";
#         OPENCLAW_CONFIG_PATH = "${config.home.homeDirectory}/${dataDir}/openclaw.json";
#         # OPENCLAW_GATEWAY_PORT
#         # OPENCLAW_GATEWAY_TOKEN
#       };
#       persist.storage.directories = [dataDir];
#       home.packages = [
#         perSystem.llm-agents.openclaw
#       ];
#       programs.zsh.initContent =
#         mkAfter
#         # sh
#         ''
#           # OpenClaw completions (generate once, async)
#           _openclaw_comp="$ZDOTDIR/openclaw"
#
#           if [[ -r "$_openclaw_comp" ]]; then
#             source "$_openclaw_comp"
#           else
#             {
#               openclaw completion --shell zsh >| "$_openclaw_comp" 2>/dev/null
#             } &!
#           fi
#         '';
#     }
#     // {
#       # home.sessionVariables = {
#       #   PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
#       # };
#       # home.sessionPath = [
#       #   "${config.home.homeDirectory}/.local/share/pnpm"
#       # ];
#       # persist.scratch.directories = [".local/share/pnpm"];
#       # home.packages = [
#       #   pkgs.nodejs_24
#       #   pkgs.pnpm
#       # ];
#     });
# }

