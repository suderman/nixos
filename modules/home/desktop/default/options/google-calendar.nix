# programs.google-calendar.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.google-calendar;
  inherit (lib) mkIf mkOption options types;
  class = config.lib.chromium.mkClass {
    inherit (cfg) url profile;
    keydify = true;
  };
in {
  options.programs.google-calendar = {
    enable = options.mkEnableOption "google-calendar";
    url = mkOption {
      type = types.str;
      default = "https://calendar.google.com/";
    };
    profile = mkOption {
      type = with lib.types; nullOr str;
      default = "work";
    };
  };

  config = mkIf cfg.enable {
    services.keyd.windows."${class}" = {
      "super.[" = "A-left"; # back
      "super.]" = "A-right"; # forward
    };
    xdg.desktopEntries = config.lib.chromium.mkWebApp {
      name = "Google Calendar";
      inherit (cfg) url profile;
      icon =
        pkgs.writeText "icon.svg"
        # html
        ''
          <svg xmlns="http://www.w3.org/2000/svg" width="2500" height="2500" viewBox="0 0 200 200"><path fill="#fff" d="m152.632 47.368-47.368-5.263-57.895 5.263L42.105 100l5.263 52.632L100 159.211l52.632-6.579 5.263-53.947z"/><path fill="#1a73e8" d="M68.961 129.026c-3.934-2.658-6.658-6.539-8.145-11.671l9.132-3.763c.829 3.158 2.276 5.605 4.342 7.342 2.053 1.737 4.553 2.592 7.474 2.592 2.987 0 5.553-.908 7.697-2.724s3.224-4.132 3.224-6.934c0-2.868-1.132-5.211-3.395-7.026s-5.105-2.724-8.5-2.724h-5.276v-9.039h4.736c2.921 0 5.382-.789 7.382-2.368s3-3.737 3-6.487c0-2.447-.895-4.395-2.684-5.855s-4.053-2.197-6.803-2.197c-2.684 0-4.816.711-6.395 2.145s-2.724 3.197-3.447 5.276l-9.039-3.763c1.197-3.395 3.395-6.395 6.618-8.987 3.224-2.592 7.342-3.895 12.342-3.895 3.697 0 7.026.711 9.974 2.145 2.947 1.434 5.263 3.421 6.934 5.947 1.671 2.539 2.5 5.382 2.5 8.539 0 3.224-.776 5.947-2.329 8.184s-3.461 3.947-5.724 5.145v.539a17.379 17.379 0 0 1 7.342 5.724c1.908 2.566 2.868 5.632 2.868 9.211s-.908 6.776-2.724 9.579-4.329 5.013-7.513 6.618C89.355 132.184 85.763 133 81.776 133c-4.618.013-8.881-1.316-12.815-3.974zM125 83.711l-9.974 7.25-5.013-7.605L128 70.382h6.895v61.197H125z"/><path fill="#ea4335" d="M152.632 200 200 152.632l-23.684-10.526-23.684 10.526-10.526 23.684z"/><path fill="#34a853" d="M36.842 176.316 47.368 200h105.263v-47.368H47.368z"/><path fill="#4285f4" d="M15.789 0C7.066 0 0 7.066 0 15.789v136.842l23.684 10.526 23.684-10.526V47.368h105.263l10.526-23.684L152.632 0z"/><path fill="#188038" d="M0 152.632v31.579C0 192.935 7.066 200 15.789 200h31.579v-47.368z"/><path fill="#fbbc04" d="M152.632 47.368v105.263H200V47.368l-23.684-10.526z"/><path fill="#1967d2" d="M200 47.368V15.789C200 7.065 192.934 0 184.211 0h-31.579v47.368z"/></svg>
        '';
    };
  };
}
