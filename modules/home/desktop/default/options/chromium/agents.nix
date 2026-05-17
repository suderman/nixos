{
  config,
  lib,
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
        text =
          ''
            mkdir -p "${cfg.dataDir}-agent"
            rm -f "${cfg.dataDir}-agent/External Extensions"
            ln -sf "${cfg.dataDir}/External Extensions" "${cfg.dataDir}-agent/External Extensions"
          ''
          + "${lib.getExe cfg.package} "
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
