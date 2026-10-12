{pkgs, ...}: {
  programs.waybar.settings.bar = let
    mkLayout = name: icon: {
      on-click = "exec hypr-layout ${name}";
      on-scroll-up = "exec hyprctl dispatch 'hl.dsp.layout(\"move -col\")'";
      on-scroll-down = "exec hyprctl dispatch 'hl.dsp.layout(\"move +col\")'";
      signal = 8;
      return-type = "json";
      exec = pkgs.self.mkScript {
        path = [pkgs.jq];
        text =
          # bash
          ''
            class=""
            hypr-activeworkspace | jq -e '.tiledLayout == "${name}"' >/dev/null && class="active"
            echo '{"text": "${icon}", "tooltip": "${name}", "class": "'"$class"'"}'
          '';
      };
    };
  in {
    modules-left = [
      "custom/launcher"
      "hyprland/workspaces"
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

    # Indicator for fullscreen mode or hidden floating windows per workspace
    "custom/windows" = {
      on-click = "exec hypr-togglefullscreenorhidden";
      signal = 9;
      return-type = "json";
      exec = pkgs.self.mkScript {
        path = [pkgs.jq];
        text =
          # bash
          ''
            mode="$(hyprctl -j activewindow | jq -r '.fullscreen // 0')"
            if [[ "$mode" == "1" ]]; then
              echo '{"text": "  ", "tooltip": "Fullscreen mode", "class": "active"}'
            elif [[ "$mode" != "0" ]]; then
              echo '{"text": ""}'
            else
              ws="special:hidden$(hypr-activeworkspace | jq -r .selector)"
              count=$(hyprctl -j clients | jq --arg ws "$ws" '[.[] | select(.workspace.name == $ws and .floating)] | length')
              if (( count < 1 )); then
                echo '{"text": ""}'
              elif (( count == 1 )); then
                echo '{"text": "  ", "tooltip": "1 hidden window", "class": "active"}'
              else
                echo '{"text": "  ", "tooltip": "'$count' hidden windows", "class": "active"}'
              fi
            fi
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
}
