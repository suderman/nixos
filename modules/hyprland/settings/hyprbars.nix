{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf mkShellScript;

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

  toggleFloating = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      # Save active window address
      addr="$(hyprctl activewindow -j | jq -r .address)"

      # Toggle floating and get status
      hyprctl --batch "dispatch togglefloating address:$addr ; dispatch focuswindow address:$addr"
      is_floating="$(hyprctl clients -j | jq ".[] | select(.address==\"$addr\") .floating")"

      # If window is now floating, resize and centre
      if [[ "$is_floating" == "true" ]]; then
        hyprctl --batch "dispatch resizeactive exact 50% 50% ; dispatch centerwindow 1"
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
          bar_color = "rgba(00000000)";

          bar_part_of_window = false;
          bar_precedence_over_border = false; 
          bar_title_enabled = false;
          # col.text = "rgb(000000)";
          # bar_text_size = 12; 
          # bar_text_font = "Jetbrains Mono Nerd Font Mono Bold";

          hyprbars-button = let 
            button = icon: command: "rgba(00000050), 20, ${icon}, ${command}"; 
          in [
            ( button "" "hyprctl dispatch exec ${toggleGroupOrKill}" ) # kill
            ( button "ᘐ" "hyprctl dispatch exec ${toggleGroupOrLock}" ) # group
            ( button "ᓬ" "hyprctl dispatch exec ${toggleSpecial}" )     # special
            ( button "❖" "hyprctl dispatch exec ${toggleFloating}" )    # float
            ( button "✚" "hyprctl dispatch fullscreen 1" )              # full
          ];

        }; 

        bind = [

          # Toggle floating or tiled windows
          "super+alt, i, exec, ${toggleFloating}"

          # Minimize windows (send to special workspace) and restore
          "super+alt, escape, exec, ${toggleSpecial}"

          # Manage groups
          "super, g, exec, ${toggleGroupOrLock}"
          "super+shift, g, togglegroup," # release windows from group
          "super, semicolon, changegroupactive, b" # prev window in group
          "super, apostrophe, changegroupactive, f" # next window in group

        ];

      };

    };
  };

}
