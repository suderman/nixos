# services.openclaw.enable = true;
{
  config,
  lib,
  perSystem,
  ...
}: let
  cfg = config.services.openclaw;
  user = config.home-manager.users."${cfg.username}" or null;
  runDir = "/run/openclaw";
in {
  options.services.openclaw = {
    enable = lib.mkEnableOption "openclaw";
    package = lib.mkOption {
      type = lib.types.package;
      default = perSystem.llm-agents.openclaw;
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "bot";
      description = "Name of user on this host to run the OpenClaw gateway";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 11000 + user.home.portOffset;
      example = 11000;
      description = "Port number to run the OpenClaw gateway";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = ".openclaw";
    };
  };

  config = lib.mkIf (cfg.enable && user != null) {
    services.traefik.proxy."${cfg.username}" = cfg.port;

    system.activationScripts.openclawGatewayToken.text = let
      inherit (perSystem.self) mkScript;
      hex = config.age.secrets.hex.path;
      text =
        # bash
        ''
          if [[ -f ${hex} ]]; then
            install -d -m 775 /run/openclaw
            cat ${hex} |
            derive hex ${cfg.username} >/run/openclaw/gateway
            chown -R ${cfg.username}:users /run/openclaw
          fi
        '';
      path = [perSystem.self.derive];
    in
      lib.mkAfter "${mkScript {inherit text path;}}";

    # home-manager.users."${cfg.username}" = {
    #
    # persist.storage.directories = [cfg.dataDir];
    #
    # systemd.user.services.openclaw-env = {
    #   Unit = {
    #     Description = "OpenClaw Prepare Gateway Environment";
    #     After = ["network-online.target"];
    #     Wants = ["network-online.target"];
    #   };
    #   Service = {
    #     Type = "oneshot";
    #
    #     ExecStart = perSystem.self.mkScript {
    #       text =
    #         # bash
    #         ''
    #           cat >/run/openclaw/gateway.env <<EOF
    #           OPENCLAW_GATEWAY_TOKEN=$(cat /run/openclaw/gateway)
    #           EOF
    #         '';
    #     };
    #
    #     Restart = "on-failure";
    #     RestartSec = 2;
    #   };
    #   Install.WantedBy = ["default.target"];
    # };
    #
    # systemd.user.services.openclaw-gateway = {
    #   Unit = {
    #     Description = "OpenClaw Gateway";
    #     After = ["network-online.target" "openclaw-env"];
    #     Wants = ["network-online.target" "openclaw-env"];
    #   };
    #
    #   Service = {
    #     Type = "simple";
    #
    #     EnvironmentFile = "${runDir}/gateway.env";
    #     Environment = [
    #       "OPENCLAW_STATE_DIR=${user.home.homeDirectory}/${cfg.dataDir}"
    #       "OPENCLAW_GATEWAY_PORT=${toString cfg.port}"
    #     ];
    #
    #     ExecStart = "${cfg.package}/bin/openclaw gateway";
    #
    #     Restart = "on-failure";
    #     RestartSec = 2;
    #
    #     # Hardening
    #     NoNewPrivileges = true;
    #     PrivateTmp = true;
    #     ProtectSystem = "strict";
    #     ProtectHome = false;
    #     ProtectKernelTunables = true;
    #     ProtectKernelModules = true;
    #     ProtectControlGroups = true;
    #     LockPersonality = true;
    #     MemoryDenyWriteExecute = false;
    #   };
    #
    #   Install.WantedBy = ["default.target"];
    # };
    #
    # programs = {
    #   openclaw = {
    #     enable = true;
    #     host = "${cfg.username}.${config.networking.hostName}";
    #     port = 443;
    #     package = cfg.package;
    #   };
    #
    #   javascript.enable = true;
    #   python.enable = true;
    # };
    # };
  };
}
