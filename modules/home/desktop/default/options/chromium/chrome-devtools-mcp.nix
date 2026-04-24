{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.chrome-devtools-mcp;
in {
  options.services.chrome-devtools-mcp = {
    enable = lib.mkEnableOption "chrome-devtools-mcp";
  };

  config = lib.mkIf cfg.enable {
    toolchains.javascript.enable = true;

    # Expose the browser URL to the MCP at a well-known path
    xdg.configFile."chrome-devtools-mcp/browser-url" = {
      text = "http://127.0.0.1:${toString config.programs.chromium.remoteDebuggingPort}";
    };

    systemd.user.services.chrome-devtools-mcp = let
      port = toString config.programs.chromium.remoteDebuggingPort;
    in {
      Unit = {
        Description = "Chrome DevTools MCP Server";
        Documentation = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };

      Service = {
        Type = "simple";

        Environment = [
          "PATH=${lib.concatStringsSep ":" config.home.sessionPath}:/run/current-system/sw/bin:/usr/bin:/bin"
          "XDG_RUNTIME_DIR=${config.home.homeDirectory}/.local/state"
        ];

        # Kill any stale MCP processes before starting fresh
        ExecStartPre = [
          "${pkgs.procps}/bin/pkill -f 'chrome-devtools-mcp.*127.0.0.1:${port}' || true"
          "${pkgs.bash}/bin/sleep 1"
        ];

        ExecStart = toString [
          "${pkgs.nodejs}/bin/node"
          "${pkgs.nodejs}/bin/npx"
          "-y"
          "chrome-devtools-mcp@latest"
          "--browser-url=http://127.0.0.1:${port}"
          "--no-usage-statistics"
        ];

        Restart = "on-failure";
        RestartSec = "3";
        TimeoutStopSec = "10";

        # Hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        NoNewPrivileges = true;
        MemoryDenyWriteExecute = false;

        # Resource limits
        LimitNOFILE = 65536;
      };

      Install.WantedBy = ["default.target"];
    };
  };
}
