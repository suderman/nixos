{
  config,
  lib,
  pkgs,
  perSystem,
  ...
}: let
  cfg = config.programs.chromium;
  inherit (config.lib.chromium) switches;
  inherit (perSystem.self) mkApplication;
  dataDir = ".config/chromium";
in {
  config = lib.mkIf cfg.enable {
    # Persist reboots but skip backups
    persist.scratch.directories = ["${dataDir}-agent"];

    # Isolated agent variant of chromium with remote debugging port
    home.packages = [
      (mkApplication {
        name = "chromium-agent";
        desktopName = "Chromium Agent";
        genericName = "Web Browser";
        categories = ["Network" "WebBrowser"];
        icon = "chromium";
        path = [pkgs.procps];
        text =
          ''
            data_dir="${cfg.dataDir}-agent"
            profile_pattern="[c]hromium.*--user-data-dir=$data_dir"

            if pgrep -f -- "$profile_pattern" >/dev/null; then
              pkill -TERM -f -- "$profile_pattern" || true
              for _ in {1..50}; do
                pgrep -f -- "$profile_pattern" >/dev/null || break
                sleep 0.1
              done
              pkill -KILL -f -- "$profile_pattern" || true
            fi

            mkdir -p "$data_dir"
            rm -f "$data_dir"/Singleton{Cookie,Lock,Socket}
            rm -rf "$data_dir/Default/Sessions"
            rm -f "$data_dir/Default"/{Current,Last}\ {Session,Tabs}
            rm -f "$data_dir/External Extensions"
            ln -sf "${cfg.dataDir}/External Extensions" "$data_dir/External Extensions"
          ''
          + "exec ${lib.getExe cfg.package} "
          + toString (
            switches
            ++ [
              ''--user-data-dir=${cfg.dataDir}-agent''
              ''--disk-cache-dir=${cfg.runDir}-agent''
              ''--profile-directory=Default''
              "--remote-debugging-port=${toString cfg.remoteDebuggingPort}"
            ]
          )
          + " \"$@\"";
      })
    ];
  };
}
