{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkShellScript;

  toggleGroupOrKill = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"
      if (( grouped_windows_count > 1 )); then
        hyprctl dispatch togglegroup
      else
        hyprctl dispatch killactive
      fi
    '';
  };

  toggleGroupOrLock = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"
      if (( grouped_windows_count > 1 )); then
        hyprctl dispatch lockactivegroup toggle
      else
        hyprctl dispatch togglegroup
      fi
    '';
  };

  toggleGroupOrLockOrNavigate = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      btn="$(cat /run/keyd/button)"
      grouped_windows_count="$(hyprctl activewindow -j | jq '.grouped | length')"

      # toggle group lock
      if [[ "$btn" == "right" ]]; then

        if (( grouped_windows_count > 1 )); then
          hyprctl dispatch lockactivegroup toggle
        else
          hyprctl dispatch togglegroup
        fi

      # prev window in group
      elif [[ "$btn" == "middle" ]]; then
        if (( grouped_windows_count > 1 )); then
          hyprctl dispatch changegroupactive b
        else
          hyprctl dispatch togglegroup
        fi

      # next window in group
      else
        if (( grouped_windows_count > 1 )); then
          hyprctl dispatch changegroupactive f
        else
          hyprctl dispatch togglegroup
        fi
      fi
    '';
  };

  toggleSpecial = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      id="$(hyprctl activewindow -j | jq -r .workspace.id)"
      if (( id < 0 )); then 
        hyprctl dispatch movetoworkspace e+0
      else 
        hyprctl dispatch movetoworkspacesilent special
      fi
    '';
  };

  toggleFullscreenOrFloating = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      btn="$(cat /run/keyd/button)"

      # toggle fullscreen
      if [[ "$btn" == "left" ]]; then
        hyprctl dispatch fullscreen 1   # act like only window in workspace

      # toggle fullscreen (no waybar)
      elif [[ "$btn" == "middle" ]]; then
        hyprctl dispatch fullscreen 0   # actual fullscreen

      # toggle floating
      else

        # Save active window address
        addr="$(hyprctl activewindow -j | jq -r .address)"

        # Toggle floating and get status
        hyprctl --batch "dispatch togglefloating address:$addr ; dispatch focuswindow address:$addr"
        is_floating="$(hyprctl clients -j | jq ".[] | select(.address==\"$addr\") .floating")"

        # If window is now floating, resize and centre
        if [[ "$is_floating" == "true" ]]; then
          hyprctl --batch "dispatch resizeactive exact 50% 50% ; dispatch centerwindow 1"
        fi

      fi
    '';
  };


in {

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {

      plugins = [ pkgs.hyprlandPlugins.hyprbars ];

      settings = {
        "plugin:hyprbars" = {

          bar_height = 30; 
          bar_padding = 10;
          bar_button_padding = 7; 
          # bar_color = "rgba(00000000)";
          # bar_color = "rgba(151521b3)";
          bar_color = "rgba(151521d9)";

          bar_part_of_window = false;
          bar_precedence_over_border = false; 
          # bar_title_enabled = false;
          bar_title_enabled = true;
          # col.text = "rgb(000000)";
          # bar_text_size = 12; 
          # bar_text_font = "Jetbrains Mono Nerd Font Mono Bold";

          hyprbars-button = let 
            # button = icon: command: "rgba(00000050), 20, ${icon}, ${command}"; 
            button = icon: command: "rgba(1515214d), 20, ${icon}, ${command}"; 
          in [
            ( button "" "hyprctl dispatch exec ${toggleGroupOrKill}" ) # kill
            ( button "ᘐ" "hyprctl dispatch exec ${toggleGroupOrLockOrNavigate}" ) # group
            ( button "ᓬ" "hyprctl dispatch exec ${toggleSpecial}" )     # special
            ( button "❖" "hyprctl dispatch exec ${toggleFullscreenOrFloating}" ) # window
          ];

        }; 

        bind = [

          # Kill the group or window
          "super, q, exec, ${toggleGroupOrKill}"

          # Minimize windows (send to special workspace) and restore
          "super+alt, escape, exec, ${toggleSpecial}"
          "super, escape, togglespecialworkspace" # toggle special workspace

          # Manage groups with [/] [;] [']
          "super, slash, exec, ${toggleGroupOrLock}"
          # "super, semicolon, changegroupactive, b" # prev window in group
          # "super, apostrophe, changegroupactive, f" # next window in group
          "super, comma, changegroupactive, b" # prev window in group
          "super, period, changegroupactive, f" # next window in group

          # Toggle floating or tiled windows
          "super+alt, i, exec, ${toggleFullscreenOrFloating}"

        ];

      };

    };
  };

}
