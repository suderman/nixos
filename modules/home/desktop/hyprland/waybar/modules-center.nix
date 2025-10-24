{
  lib,
  pkgs,
  ...
}: {
  programs.waybar.settings.bar = {
    modules-center = [
      "clock"
      "custom/hidden"
      "custom/screencast"
    ];

    clock = {
      format = "{:%b %e %I:%M %p}";
      format-alt = "{:%A %d %B W%V %Y}";
      on-click-right = "${lib.getExe pkgs.gsimplecal}";
      interval = 60;
      align = 0;
      rotate = 0;
      tooltip-format = "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>";
      calendar = {
        mode = "year";
        mode-mon-col = 3;
        weeks-pos = "right";
        on-scroll = 1;
        on-click-right = "mode";
        format = {
          months = "<span color='#ffead3'><b>{}</b></span>";
          days = "<span color='#ff9aef'><b>{}</b></span>";
          weeks = "<span color='#85dff8'><b>W{}</b></span>";
          weekdays = "<span color='#f2e1d1'><b>{}</b></span>";
          today = "<span color='#ff8994'><b><u>{}</u></b></span>";
        };
      };
    };

    # Counter for hidden floating windows per workspace
    "custom/hidden" = {
      on-click = "exec hypr-togglefloatinghidden";
      return-type = "json";
      exec = pkgs.self.mkScript {
        path = with pkgs; [coreutils jq socat];
        text =
          # bash
          ''
            handle() {
              case $1 in
              activewindowv2\>\>*)
                ws="special:hidden$(hyprctl activeworkspace -j | jq -r '.id')" # get hidden ws name from current ws
                count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$ws\")] | length") # count hidden windows
                if (( count > 0 )); then
                  echo "{\"text\": \"  \", \"tooltip\": \"$count hidden windows\", \"class\": \"active\"}"
                else
                  echo '{"text": ""}'
                fi
                ;;
              esac
            }
            socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
          '';
      };
    };

    "custom/screencast" = {
      on-click = "printscreen video";
      signal = 8;
      return-type = "json";
      exec = pkgs.self.mkScript {
        text =
          # bash
          ''
            if [[ "$(printscreen status)" == "video" ]]; then
              echo '{"text": " 󰻂 ", "tooltip": "Stop recording", "class": "active"}'
            else
              echo '{"text": ""}'
            fi
          '';
      };
    };
  };
}
