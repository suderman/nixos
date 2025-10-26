{pkgs, ...}: {
  programs.waybar.settings.bar = {
    modules-left = [
      "custom/launcher"
      "hyprland/workspaces"
      "custom/fullscreen"
      "custom/hidden"
    ];

    "custom/launcher" = {
      on-click = "launcher";
      on-click-right = "blezz";
      format = "";
    };

    "hyprland/workspaces" = {
      on-click = "activate";
      all-outputs = false;
      disable-scroll = true;
      active-only = false;
      show-special = false;
      format = "{icon}";
      format-icons = {
        default = "";
        "1" = "1";
        "2" = "2";
        "3" = "3";
        "4" = "4";
        "5" = "5";
        "6" = "6";
        "7" = "7";
        "8" = "8";
        "9" = "9";
      };
    };

    # Indicator for fullscreen mode per workspace
    "custom/fullscreen" = {
      on-click = "exec hyprctl dispatch fullscreen 1";
      return-type = "json";
      exec = pkgs.self.mkScript {
        path = with pkgs; [coreutils jq socat];
        text =
          # bash
          ''
            handle() {
              case $1 in
              fullscreen\>\>*)
                if [[ "$(hyprctl activewindow -j | jq '.fullscreen')" != "0" ]]; then
                  echo '{"text": "  ", "tooltip": "Fullscreen mode", "class": "active"}'
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
              activewindowv2\>\>*|fullscreen\>\>*)
                ws="special:hidden$(hyprctl activeworkspace -j | jq -r '.id')" # get hidden ws name from current ws
                count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$ws\")] | length") # count hidden windows
                [[ "$(hyprctl activewindow -j | jq '.fullscreen')" != "0" ]] && count=0 # override count to 0 if fullscreen
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
  };
}
