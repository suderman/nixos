# programs.khal.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.khal;
  inherit (lib) mkIf;

  # Wrapper to redirect warnings to log file, default command is interactive
  package = pkgs.unstable.khal;
  khal-wrapper = pkgs.self.mkScript {
    name = "khal";
    text =
      # bash
      ''
        mkdir -p "${config.xdg.stateHome}/khal"
        [[ "$#" -eq 0 ]] && set -- interactive
        exec ${package}/bin/khal -v WARNING -l "${config.xdg.stateHome}/khal/khal.log" "$@"
      '';
  };
in {
  config = mkIf cfg.enable {
    programs.khal = {
      package = khal-wrapper;
      settings = {
        default = {
          # default_event_alarm = "15m";
          default_event_duration = "30m";
          highlight_event_days = true;
          show_all_days = true; # show days without events too
          timedelta = "7d"; # show 1 week into the future
        };
        keybindings = {
          external_edit = "e";
          export = "w";
          save = "meta w,<0>";
          view = "enter, ";
        };
        highlight_days = {
          method = "fg";
          multiple = "#0000FF";
          multiple_on_overflow = true;
        };
        view = {
          dynamic_days = false;
          event_view_always_visible = true;
          frame = "color";
        };
        # palette = {
        #   header = "'white', 'dark green', default, '#DDDDDD', '#2E7D32'";
        #   "line header" = "'white', 'dark green', default, '#DDDDDD', '#2E7D32'";
        #   footer = "'white', 'black', bold, '#DDDDDD', '#43A047'";
        #   edit = "'white', 'black', default, '#DDDDDD', '#333333'";
        #   "edit focus" = "'white', 'light green', 'bold'";
        #   button = "'black', 'red'";
        # };
      };
    };

    # Pre-warm the khal database after vdirsyncer finishes
    systemd.user.services.vdirsyncer.Service.ExecStartPost = [
      (
        pkgs.self.mkScript {
          path = [cfg.package];
          text = "khal list >/dev/null || true";
        }
      )
    ];
  };
}
