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
          hyprctl dispatch lockactivegroup lock
          hyprctl dispatch changegroupactive b
        else
          hyprctl dispatch togglegroup
        fi

      # next window in group
      else
        if (( grouped_windows_count > 1 )); then
          hyprctl dispatch lockactivegroup lock
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

  toggleFullscreenOrSpecial = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      btn="$(cat /run/keyd/button)"
      
      # minimize to special
      if [[ "$btn" == "right" ]]; then

        id="$(hyprctl activewindow -j | jq -r .workspace.id)"
        if (( id < 0 )); then 
          hyprctl dispatch movetoworkspace e+0
        else 
          hyprctl dispatch movetoworkspacesilent special
        fi

      # toggle fullscreen (no waybar)
      elif [[ "$btn" == "middle" ]]; then
        hyprctl dispatch fullscreen 0
        
      # toggle fullscreen
      else
        hyprctl dispatch fullscreen 1
      fi
    '';
  };

  toggleFloatingOrSplit = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      btn="$(cat /run/keyd/button)"
      
      # Save active window address
      addr="$(hyprctl activewindow -j | jq -r .address)"

      # Get floating status
      is_floating="$(hyprctl clients -j | jq ".[] | select(.address==\"$addr\") .floating")"

      # toggle split/pin
      if [[ "$btn" == "right" ]]; then

        # if floating, pin window
        if [[ "$is_floating" == "true" ]]; then
          hyprctl dispatch pin

        # if tiled, toggle the split
        else
          hyprctl --batch "dispatch togglesplit ; dispatch focuswindow address:$addr"
        fi

      # toggle pseudo (only applies to tiled)
      elif [[ "$btn" == "middle" ]]; then
        hyprctl dispatch pseudo

      # toggle floating
      else

        # Toggle floating and get status
        hyprctl --batch "dispatch togglefloating address:$addr ; dispatch focuswindow address:$addr"

        # If window is now floating (wasn't before), resize and centre
        if [[ "$is_floating" != "true" ]]; then
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
          bar_color = "rgba(151521d9)";

          bar_part_of_window = false;
          bar_precedence_over_border = false; 
          bar_title_enabled = true;

          hyprbars-button = let 
            button = icon: command: "rgba(1515214d), 20, ${icon}, ${command}"; 
          in [
            ( button "" "hyprctl dispatch exec ${toggleGroupOrKill}" ) # kill
            ( button "ᘐ" "hyprctl dispatch exec ${toggleGroupOrLockOrNavigate}" ) # group
            ( button "ᓬ" "hyprctl dispatch exec ${toggleFullscreenOrSpecial}" )   # max/min
            ( button "❖" "hyprctl dispatch exec ${toggleFloatingOrSplit}" ) # window
          ];

        }; 

        bind = [

          # Kill the group or window
          "super, q, exec, ${toggleGroupOrKill}"

          # Minimize windows (send to special workspace) and restore
          "super+alt, escape, exec, ${toggleSpecial}"
          "super, escape, togglespecialworkspace" # toggle special workspace

          # Toggle floating or tiled windows
          "super+alt, i, exec, ${toggleFloatingOrSplit}"

          # Prev window in group with super+comma [<]
          "super, comma, changegroupactive, b" 
          "super, comma, lockactivegroup, lock"

          # Next window in group with super+period [>]
          "super, period, changegroupactive, f" 
          "super, period, lockactivegroup, lock"

          # Fullscreen toggle
          "alt, return, fullscreen, 0"

        ];

        # Toggle group lock with super+comma+period ([<>] same-time)
        bindsn = [
          "super_l, comma&period, exec, ${toggleGroupOrLock}"
          "super_r, comma&period, exec, ${toggleGroupOrLock}"
        ];

      };

    };
  };

}
