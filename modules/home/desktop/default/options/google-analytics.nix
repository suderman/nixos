# programs.google-analytics.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.google-analytics;
  inherit (lib) mkIf mkOption options types;
  inherit (config.programs.chromium.lib) mkClass mkWebApp;
in {
  options.programs.google-analytics = {
    enable = options.mkEnableOption "google-analytics";
    url = mkOption {
      type = types.str;
      default = "https://analytics.google.com/";
    };
    profile = mkOption {
      type = with lib.types; nullOr str;
      default = "team";
    };
  };

  config = mkIf cfg.enable {
    services.keyd.windows = {
      "${mkClass cfg.url}" = {
        "super.[" = "A-left"; # back
        "super.]" = "A-right"; # forward
      };
    };
    xdg.desktopEntries = mkWebApp {
      name = "Google Analytics";
      inherit (cfg) url profile;
      icon =
        pkgs.writeText "icon.svg"
        # html
        ''
          <svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" style="enable-background:new 0 0 2195.9 2430.9" viewBox="0 0 2195.9 2430.9"><path d="M2195.9 2126.7c.9 166.9-133.7 302.8-300.5 303.7-12.4.1-24.9-.6-37.2-2.1-154.8-22.9-268.2-157.6-264.4-314V316.1c-3.7-156.6 110-291.3 264.9-314 165.7-19.4 315.8 99.2 335.2 264.9 1.4 12.2 2.1 24.4 2 36.7v1823z" style="fill:#f9ab00"/><path d="M301.1 1828.7c166.3 0 301.1 134.8 301.1 301.1s-134.8 301.1-301.1 301.1S0 2296.1 0 2129.8s134.8-301.1 301.1-301.1zm792.2-912.5c-167.1 9.2-296.7 149.3-292.8 316.6v808.7c0 219.5 96.6 352.7 238.1 381.1 163.3 33.1 322.4-72.4 355.5-235.7 4.1-20 6.1-40.3 6-60.7v-907.4c.3-166.9-134.7-302.4-301.6-302.7-1.7 0-3.5 0-5.2.1z" style="fill:#e37400"/></svg>
        '';
    };
  };
}
