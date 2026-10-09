{
  config,
  lib,
  osConfig,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.fresha-org;
  fresha-org = perSystem.self.mkScript {
    name = "fresha-org";
    text = ''
      exec ${lib.getExe pkgs.nodejs_24} ${./fresha-org.js} "$@"
    '';
  };
  sync = perSystem.self.mkScript {
    name = "fresha-org-sync";
    path = [pkgs.curl];
    text =
      # bash
      ''
        dir="$(dirname ${lib.escapeShellArg cfg.orgFile})"
        mkdir -p "$dir"

        tmp="$(mktemp "$dir/.fresha-org.tmp.XXXXXX")"
        trap 'rm -f "$tmp"' EXIT

        cdp_url="http://127.0.0.1:9222/json/version"
        cdp_ready() {
          curl --fail --silent --max-time 1 "$cdp_url" >/dev/null
        }

        if ! cdp_ready; then
          ${lib.getExe' osConfig.programs.hyprland.package "hyprctl"} dispatch 'hl.dsp.exec_cmd("chromium-agent")'
          for _ in {1..40}; do
            cdp_ready && break
            sleep 0.25
          done
          if ! cdp_ready; then
            echo "chromium-agent did not open CDP port 9222" >&2
            exit 1
          fi
        fi

        ${lib.getExe fresha-org} >"$tmp"
        mv "$tmp" ${lib.escapeShellArg cfg.orgFile}
        trap - EXIT
      '';
  };
in {
  options.programs.fresha-org = {
    enable = lib.mkEnableOption "Fresha staff shifts as Org events";

    orgFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Org file refreshed twice daily. Null disables the timer.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [fresha-org];

    systemd.user = lib.mkIf (cfg.orgFile != null) {
      services.fresha-org = {
        Unit.Description = "Write Fresha staff shifts to Org";
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe sync;
        };
      };

      timers.fresha-org = {
        Unit.Description = "Update Fresha staff shifts at 04:00 and 16:00";
        Timer = {
          OnCalendar = ["04:00" "16:00"];
          Persistent = true;
          Unit = "fresha-org.service";
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
