{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  orgFile = "${config.home.homeDirectory}/org/fresha.org";
  sync = perSystem.self.mkScript {
    name = "fresha-org-sync";
    path = [pkgs.curl];
    text = ''
      dir="$(dirname ${lib.escapeShellArg orgFile})"
      mkdir -p "$dir"

      tmp="$(mktemp "$dir/.fresha-org.tmp.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT

      cdp_url="http://127.0.0.1:9222/json/version"
      cdp_ready() {
        curl --fail --silent --max-time 1 "$cdp_url" >/dev/null
      }

      if ! cdp_ready; then
        ${config.home.profileDirectory}/bin/hyprctl dispatch 'hl.dsp.exec_cmd("chromium-agent")'
        for _ in {1..40}; do
          cdp_ready && break
          sleep 0.25
        done
        if ! cdp_ready; then
          echo "chromium-agent did not open CDP port 9222" >&2
          exit 1
        fi
      fi

      ${config.home.profileDirectory}/bin/fresha-org >"$tmp"
      mv "$tmp" ${lib.escapeShellArg orgFile}
      trap - EXIT
    '';
  };
in {
  programs.fresha-org.enable = true;

  systemd.user = {
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
}
