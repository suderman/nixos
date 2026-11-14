# programs.health-records.enable = true;
#
# Every morning after Lose It's 8:00 AM daily report: file the report from mail, pull
# the past week from Garmin Connect, check the Lose It sign-in, and rebuild
# ~/org/health. The scripts live in the private health repository checkout. The
# Garmin pull and the Lose It check open background tabs in the signed-in
# chromium-agent, which also keeps both sessions in use. They never sign in: when
# a site wants a sign-in, ntfy says so, and again every third morning until a run
# succeeds; any other failure is reported on each run.
{
  config,
  lib,
  osConfig,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.health-records;
in {
  options.programs.health-records = {
    enable = lib.mkEnableOption "daily Lose It and Garmin records in ~/org/health";
    repo = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/src/suderman/health";
      description = "Checkout of the health repository whose bin/health runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.health-records = {
      Unit.Description = "Update Lose It and Garmin records in ~/org/health";
      Service = {
        Type = "oneshot";
        Environment =
          lib.optional (config.home.sessionVariables ? NOTMUCH_CONFIG)
          "NOTMUCH_CONFIG=${toString config.home.sessionVariables.NOTMUCH_CONFIG}";
        ExecStart = lib.getExe (perSystem.self.mkScript {
          name = "health-records";
          path = [pkgs.python3 pkgs.nodejs_24 pkgs.notmuch pkgs.curl];
          text =
            # bash
            ''
              health=${lib.escapeShellArg cfg.repo}/bin/health
              state="''${XDG_STATE_HOME:-$HOME/.local/state}/health-records"
              mkdir -p "$state"
              failed=0 signin=0

              notify() {
                curl --fail --silent --show-error --max-time 20 --output /dev/null \
                  --header "Title: $1" --data "$2" https://ntfy.hub/health || true
              }

              # Run a browser step; on status 3 ask for a sign-in, again every third daily run
              # (59 hours allows for timer drift) until the site works again.
              browser() {
                local site=$1 status=0
                shift
                "$health" "$@" || status=$?
                if [ "$status" = 0 ]; then
                  rm -f "$state/signin-$site"
                  return
                fi
                if [ "$status" != 3 ]; then
                  failed=1
                  return
                fi
                signin=1
                local asked="$state/signin-$site"
                if [ ! -e "$asked" ] || [ $(($(date +%s) - $(stat -c %Y "$asked"))) -gt $((59 * 3600)) ]; then
                  notify "Sign in to $site" "health-records on $(uname -n) cannot read $site. Sign in again in chromium-agent (workspace 8); the next morning's run picks it up."
                  touch "$asked"
                fi
              }

              cdp_ready() {
                curl --fail --silent --max-time 1 http://127.0.0.1:9222/json/version >/dev/null
              }
              if ! cdp_ready; then
                ${lib.getExe' osConfig.programs.hyprland.package "hyprctl"} dispatch 'hl.dsp.exec_cmd("chromium-agent --no-startup-window")'
                for _ in {1..40}; do
                  cdp_ready && break
                  sleep 0.25
                done
              fi

              "$health" fetch || failed=1
              browser connect.garmin.com garmin
              browser loseit.com check
              "$health" build || failed=1

              if [ "$failed" = 1 ]; then
                notify "health-records failed" "health-records failed on $(uname -n). Check journalctl --user -u health-records."
              fi
              if [ "$failed" = 1 ] || [ "$signin" = 1 ]; then
                exit 1
              fi
            '';
        });
      };
    };

    systemd.user.timers.health-records = {
      Unit.Description = "Update ~/org/health after Lose It's 8:00 AM report";
      Timer = {
        OnCalendar = "*-*-* 08:45:00 America/Edmonton";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
