{
  config,
  lib,
  perSystem,
  ...
}: let
  orgFile = "${config.home.homeDirectory}/org/fresha.org";
  sync = perSystem.self.mkScript {
    name = "fresha-org-sync";
    text = ''
      dir="$(dirname ${lib.escapeShellArg orgFile})"
      mkdir -p "$dir"

      tmp="$(mktemp "$dir/.fresha-org.tmp.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT

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
