{pkgs, ...}: {
  programs.waybar.settings.bar = let
    mkLayout = name: icon: {
      on-click = "exec hypr-layout ${name}";
      on-scroll-up = "exec hyprctl -- dispatch layoutmsg move -col";
      on-scroll-down = "exec hyprctl -- dispatch layoutmsg move +col";
      signal = 8;
      return-type = "json";
      exec = pkgs.self.mkScript {
        path = [pkgs.jq];
        text =
          # bash
          ''
            class=""
            hyprctl -j activeworkspace | jq -e '.tiledLayout == "${name}"' >/dev/null && class="active"
            echo '{"text": "${icon}", "tooltip": "${name}", "class": "'"$class"'"}'
          '';
      };
    };
  in {
    modules-left = [
      "custom/launcher"
      "hyprland/workspaces"
      # "custom/layout"
      "group/layouts"
      "custom/windows"
    ];

    "custom/launcher" = {
      on-click = "launcher";
      on-click-right = "blezz";
      format = "";
    };

    "hyprland/workspaces" = {
      on-click = "activate";
      on-scroll-up = "exec hypr-workspace prev";
      on-scroll-down = "exec hypr-workspace next";

      all-outputs = false;
      disable-scroll = true;
      active-only = false;
      show-special = false;
      format = "{icon}";
      format-icons = {
        default = "";
        "1" = "󰲠 ";
        "2" = "󰲢 ";
        "3" = "󰲤 ";
        "4" = "󰲦 ";
        "5" = "󰲨 ";
        "6" = "󰲪 ";
        "7" = "󰲬 ";
        "8" = "󰲮 ";
        "9" = "󰲰 ";
      };
    };

    # Indicator for current workspace layout
    "custom/layout" = {
      on-click = "exec hypr-layout next";
      on-click-right = "exec hypr-layout prev";
      on-scroll-up = "exec hyprctl -- dispatch layoutmsg move -col";
      on-scroll-down = "exec hyprctl -- dispatch layoutmsg move +col";
      signal = 8;
      return-type = "json";
      exec = pkgs.self.mkScript {
        path = with pkgs; [jq socat];
        text =
          # bash
          ''
            layout="$(hyprctl -j activeworkspace | jq -r .tiledLayout)"
            icon="󰕴 " # dwindle
            if [[ "$layout" == "master" ]]; then
              icon="󰜩 "
            elif [[ "$layout" == "scrolling" ]]; then
              icon="󰕭 "
            elif [[ "$layout" == "monocle" ]]; then
              icon="󰹞 "
            fi
            echo '{"text": " '$icon'", "tooltip": "'$layout'", "class": "active"}'
          '';
      };
    };

    # Indicator for fullscreen mode or hidden floating windows per workspace
    "custom/windows" = {
      on-click = "exec hypr-togglefullscreenorhidden";
      return-type = "json";
      exec = pkgs.self.mkScript {
        path = with pkgs; [jq socat];
        text =
          # bash
          ''
            handle() {
              case $1 in
              activewindowv2\>\>*|fullscreen\>\>*)
                if [[ "$(hyprctl activewindow -j | jq '.fullscreen')" == "1" ]]; then # check for fullscreen mode above all
                  echo '{"text": "  ", "tooltip": "Fullscreen mode", "class": "active"}'
                else
                  ws="special:hidden$(hyprctl activeworkspace -j | jq -r '.id')" # get hidden ws name from current ws
                  count=$(hyprctl clients -j | jq "[.[] | select(.workspace.name == \"$ws\")] | length") # count hidden windows
                  [[ "$(hyprctl activewindow -j | jq '.fullscreen')" != "0" ]] && count=0 # override count to 0 if fullscreen
                  if (( count < 1 )); then
                    echo '{"text": ""}'
                  elif (( count == 1 )); then
                    echo '{"text": "  ", "tooltip": "1 hidden window", "class": "active"}'
                  else
                    echo '{"text": "  ", "tooltip": "'$count' hidden windows", "class": "active"}'
                  fi
                fi
                ;;
              esac
            }
            socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
          '';
      };
    };

    "group/layouts" = {
      orientation = "horizontal";
      modules = [
        "custom/layout-dwindle"
        "custom/layout-master"
        "custom/layout-scrolling"
        "custom/layout-monocle"
      ];
    };

    "custom/layout-dwindle" = mkLayout "dwindle" "󰕴 ";
    "custom/layout-master" = mkLayout "master" "󰜩 ";
    "custom/layout-scrolling" = mkLayout "scrolling" "󰕭 ";
    "custom/layout-monocle" = mkLayout "monocle" "󰹞 ";
  };

  # programs.waybar.settings.side = {
  #   position = "right";
  #   layer = "top";
  #   exclusive = true;
  #   passthrough = false;
  #   width = 40;
  #
  #   modules-center = [
  #     "hyprland/workspaces"
  #     "custom/layout"
  #     "group/layouts"
  #   ];
  #   "hyprland/workspaces" = {
  #     on-click = "activate";
  #     on-scroll-up = "exec hypr-workspace prev";
  #     on-scroll-down = "exec hypr-workspace next";
  #
  #     all-outputs = false;
  #     disable-scroll = true;
  #     active-only = false;
  #     show-special = false;
  #     format = "{icon}";
  #     format-icons = {
  #       default = "";
  #       "1" = "1";
  #       "2" = "2";
  #       "3" = "3";
  #       "4" = "4";
  #       "5" = "5";
  #       "6" = "6";
  #       "7" = "7";
  #       "8" = "8";
  #       "9" = "9";
  #     };
  #   };
  #
  #   # "custom/layout-dwindle" = {
  #   #   on-click = "exec hypr-cyclelayout next";
  #   #   on-scroll-up = "exec hyprctl -- dispatch layoutmsg move -col";
  #   #   on-scroll-down = "exec hyprctl -- dispatch layoutmsg move +col";
  #   #   signal = 8;
  #   #   return-type = "json";
  #   #   exec = pkgs.self.mkScript {
  #   #     path = [pkgs.jq];
  #   #     text =
  #   #       # bash
  #   #       ''
  #   #         class=""
  #   #         hyprctl -j activeworkspace | jq -e '.tiledLayout == "dwindle"' >/dev/null && class="active"
  #   #         echo '{"text": "󰕴 ", "tooltip": "dwindle", "class": "'"$class"'"}'
  #   #       '';
  #   # };
  #
  #   # "custom/layout-master" = {
  #   #   format = "󰕴 ";
  #   #   tooltip = "master";
  #   #   on-click = "exec hypr-cyclelayout next";
  #   # };
  #   #
  #   # "custom/layout-master": {
  #   #   "format": "",
  #   #   "tooltip": false,
  #   #   "on-click": "hyprctl keyword general:layout master"
  #   # },
  #   #
  #   # "custom/layout-scrolling": {
  #   #   "format": "󰕞",
  #   #   "tooltip": false,
  #   #   "on-click": "hyprctl keyword general:layout scrolling"
  #   # },
  #   #
  #   # "custom/layout-monocle": {
  #   #   "format": "󰍉",
  #   #   "tooltip": false,
  #   #   "on-click": "hyprctl keyword general:layout monocle"
  #   # }
  # };
}
