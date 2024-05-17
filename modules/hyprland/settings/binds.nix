{ lib, pkgs, this, ... }: let 

  inherit (lib) mkDefault; 
  inherit (this.lib) mkShellScript;

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


  cycleFloatingPositions = mkShellScript {
    inputs = with pkgs; [ coreutils hyprland jq ]; text = ''

      # Get the cache directory and active window name
      cache_dir="$XDG_RUNTIME_DIR/hypr/cyclefloating"
      window_address="$(hyprctl activewindow -j | jq -r .address)"

      mkdir -p $cache_dir
      touch $cache_dir/$window_address

      # top_left    top_center    top_right
      # middle_left               middle_right
      # bottom_left bottom_center bottom_right
      pos="$(cat $cache_dir/$window_address)" 
      next_pos="top_left"

      # forward or reverse
      dir="''${1:-forward}"

      if [[ "$pos" == "top_left" ]]; then 
        hyprctl --batch "dispatch movewindow u ; dispatch movewindow l"
        [[ "$dir" == "forward" ]] && next_pos="top_center" || next_pos="middle_left"

      elif [[ "$pos" == "top_center" ]]; then 
        hyprctl --batch "dispatch centerwindow 1; dispatch movewindow u"
        [[ "$dir" == "forward" ]] && next_pos="top_right" || next_pos="top_left"

      elif [[ "$pos" == "top_right" ]]; then 
        hyprctl --batch "dispatch movewindow u ; dispatch movewindow r"
        [[ "$dir" == "forward" ]] && next_pos="middle_right" || next_pos="top_center"

      elif [[ "$pos" == "middle_right" ]]; then 
        hyprctl --batch "dispatch centerwindow 1 ; dispatch movewindow r"
        [[ "$dir" == "forward" ]] && next_pos="bottom_right" || next_pos="top_right"

      elif [[ "$pos" == "bottom_right" ]]; then 
        hyprctl --batch "dispatch movewindow d ; dispatch movewindow r"
        [[ "$dir" == "forward" ]] && next_pos="bottom_center" || next_pos="middle_right"

      elif [[ "$pos" == "bottom_center" ]]; then 
        hyprctl --batch "dispatch centerwindow 1 ; dispatch movewindow d"
        [[ "$dir" == "forward" ]] && next_pos="bottom_left" || next_pos="bottom_right"

      elif [[ "$pos" == "bottom_left" ]]; then 
        hyprctl --batch "dispatch movewindow d ; dispatch movewindow l"
        [[ "$dir" == "forward" ]] && next_pos="middle_left" || next_pos="bottom_center"

      elif [[ "$pos" == "middle_left" ]]; then 
        hyprctl --batch "dispatch centerwindow 1 ; dispatch movewindow l"
        [[ "$dir" == "forward" ]] && next_pos="top_left" || next_pos="bottom_left"
      fi

      # Save the next position to file
      echo "$next_pos" > $cache_dir/$window_address
    '';
  };

  moveWindowOrGroupOrActive = mkShellScript {
    inputs = with pkgs; [ hyprland jq ]; text = ''
      is_floating="$(hyprctl activewindow -j | jq -r .floating)"
      dir="$1" # [l]eft [d]own [u]p [r]ight 
      x="$2" y="$3" # distance to move window
      if [[ "$is_floating" == "true" ]]; then
        hyprctl dispatch moveactive $x $y
      else
        hyprctl dispatch movewindoworgroup $dir 
      fi
    '';
  };

  newWindowInGroup = mkShellScript {
    inputs = with pkgs; [ coreutils hyprland jq ]; text = ''

      win() { hyprctl clients -j | jq ".[] | select(.address == \"$1\")"; }
      group_count() { echo "$(win $1)" | jq '.grouped | length'; }
      is_group() { [[ "$(group_count $1)" == "0" ]] && return 1 || return 0; }

      # Get the active window
      window="$(hyprctl activewindow -j)"

      # Find address, pid and command for active window
      addr="$(echo $window | jq -r .address)"
      pid="$(echo $window | jq -r .pid)"
      cmd=$(ps -p $pid -o command | tail -1)

      # Unlock existing group or create new unlocked group
      if $(is_group $addr); then
        hyprctl dispatch lockactivegroup unlock 
      else
        hyprctl dispatch togglegroup 
      fi

      # Wait until window is part of a group
      while ! $(is_group $addr); do sleep 0.2; done

      # Store the current group count
      count="$(group_count "$addr")"

      # Run the command
      hyprctl dispatch exec $cmd

      # Wait for the group count to increase
      while [[ "$count" -ge "$(group_count $addr)" ]]; do sleep 0.2; done

      # Lock the group
      hyprctl dispatch lockactivegroup lock
      
    '';
  };


  screenshot = mkShellScript {
    inputs = with pkgs; [ coreutils slurp grim swappy hyprpicker libnotify wl-clipboard ]; text = ''
      # Flags:
      #
      # r: region
      # s: screen
      # c: clipboard
      # f: file
      # i: interactive
      # p: pixel

      # Region to clipboard
      if [[ $1 == rc ]]; then
          grim -g "$(slurp -b '#000000b0' -c '#00000000')" - | wl-copy
          notify-send 'Copied to Clipboard' Screenshot

      # Region to file
      elif [[ $1 == rf ]]; then
          mkdir -p ~/Pictures/Screenshots
          filename=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
          grim -g "$(slurp -b '#000000b0' -c '#00000000')" $filename
          notify-send 'Screenshot Taken' $filename

      # Region to interactive
      elif [[ $1 == ri ]]; then
          grim -g "$(slurp -b '#000000b0' -c '#00000000')" - | tee >(wl-copy) | swappy -f -
          # grim -g "$(slurp -b '#000000b0' -c '#00000000')" - | swappy -f -

      # Screen to clipboard
      elif [[ $1 == sc ]]; then
          filename=~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png
          grim - | wl-copy
          notify-send 'Copied to Clipboard' Screenshot

      # Screen to file
      elif [[ $1 == sf ]]; then
          mkdir -p ~/Pictures/Screenshots
          filename=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
          grim $filename
          notify-send 'Screenshot Taken' $filename

      # Screen to interactive
      elif [[ $1 == si ]]; then
          grim - | swappy -f -

      # Colour to clipboard
      elif [[ $1 == p ]]; then
          color=$(hyprpicker -a)
          wl-copy $color
          notify-send 'Copied to Clipboard' $color
      fi
    '';
  };

in {

  bind = [
    "SUPER, Return, exec, kitty"
    "SUPER, W, killactive,"
    "SUPERSHIFT, Q, exit,"
    "SUPER, E, exec, nautilus"

    "SUPER, B, exec, firefox"
    "SUPER SHIFT, B, exec, firefox --private-window"

    "SUPER ALT, B, exec, chromium-browser"
    "SUPER SHIFT ALT, B, exec, chromium-browser --incognito"

    "SUPER, T, exec, ${newWindowInGroup}"

    "SUPER, Escape, togglespecialworkspace"
    "SUPER ALT, Escape, movetoworkspacesilent, special"

    # "SUPER, Tab, cyclenext,"
    # "SUPER SHIFT, Tab, cyclenext, prev"
    "SUPER, Tab, workspace, m+1"
    "SUPER SHIFT, Tab, workspace, m-1"

    "SUPER, Backslash, workspace, previous"

    "SUPER, bracketleft, workspace, -1"
    "SUPER, bracketright, workspace, +1"

    "SUPER SHIFT, G,  togglegroup,"
    "SUPER, G, exec, ${toggleGroupOrLock}"
    "SUPER, N, changegroupactive, f"
    "SUPER SHIFT, N, changegroupactive, b"

    "SUPER, I, togglesplit"
    "SUPER, P, pseudo"
    "SUPER, O, togglefloating"
    "SUPER, P, pin"
    "SUPER, F, fullscreen, 1"
    "SUPER ALT, F, fullscreen, 0"

    # "numlock, exec, sleep 1 && hyprctl dispatch dpms off"
    # "f9, exec, sleep 1 && hyprctl dispatch dpms off"
    # "f10, exec, sleep 1 && hyprctl dispatch dpms on"

    "SUPER, Space, exec, tofi-drun --drun-launch=true"

    # Move focus with mainMod + arrow keys
    "SUPER, H, movefocus, l"
    "SUPER, J, movefocus, d"
    "SUPER, K, movefocus, u"
    "SUPER, L, movefocus, r"

    # Switch workspaces with mainMod + [0-9]
    "SUPER, 1, workspace, 1"
    "SUPER, 2, workspace, 2"
    "SUPER, 3, workspace, 3"
    "SUPER, 4, workspace, 4"
    "SUPER, 5, workspace, 5"
    "SUPER, 6, workspace, 6"
    "SUPER, 7, workspace, 7"
    "SUPER, 8, workspace, 8"
    "SUPER, 9, workspace, 9"
    "SUPER, 0, workspace, 10"

    # Move active window to a workspace with mainMod + ALT + [0-9]
    "SUPER ALT, 1, movetoworkspace, 1"
    "SUPER ALT, 2, movetoworkspace, 2"
    "SUPER ALT, 3, movetoworkspace, 3"
    "SUPER ALT, 4, movetoworkspace, 4"
    "SUPER ALT, 5, movetoworkspace, 5"
    "SUPER ALT, 6, movetoworkspace, 6"
    "SUPER ALT, 7, movetoworkspace, 7"
    "SUPER ALT, 8, movetoworkspace, 8"
    "SUPER ALT, 9, movetoworkspace, 9"
    "SUPER ALT, 0, movetoworkspace, 10"

    "SUPER SHIFT, 1, resizeactive, exact 10% 10%"
    "SUPER SHIFT, 1, centerwindow, 1"
    "SUPER SHIFT, 2, resizeactive, exact 20% 20%"
    "SUPER SHIFT, 2, centerwindow, 1"
    "SUPER SHIFT, 3, resizeactive, exact 30% 30%"
    "SUPER SHIFT, 3, centerwindow, 1"
    "SUPER SHIFT, 4, resizeactive, exact 40% 40%"
    "SUPER SHIFT, 4, centerwindow, 1"
    "SUPER SHIFT, 5, resizeactive, exact 50% 50%"
    "SUPER SHIFT, 5, centerwindow, 1"
    "SUPER SHIFT, 6, resizeactive, exact 60% 60%"
    "SUPER SHIFT, 6, centerwindow, 1"
    "SUPER SHIFT, 7, resizeactive, exact 70% 70%"
    "SUPER SHIFT, 7, centerwindow, 1"
    "SUPER SHIFT, 8, resizeactive, exact 80% 80%"
    "SUPER SHIFT, 8, centerwindow, 1"
    "SUPER SHIFT, 9, resizeactive, exact 90% 90%"
    "SUPER SHIFT, 9, centerwindow, 1"

    "SUPER SHIFT, 0, centerwindow, 1"
    "SUPER SHIFT, O, resizeactive, exact 600 400"

    "SUPER ALT, O, centerwindow, 1"
    "SUPER ALT, I, exec, ${cycleFloatingPositions}"
    "SUPER SHIFT ALT, I, exec, ${cycleFloatingPositions} reverse"

    # Super+m to minimize window, Super+m to bring it back (possibly on a different workspace)
    "SUPER, m, togglespecialworkspace, mover"
    "SUPER, m, movetoworkspace, +0"
    "SUPER, m, togglespecialworkspace, mover"
    "SUPER, m, movetoworkspace, special:mover"
    "SUPER, m, togglespecialworkspace, mover"

    # Screenshot a region
    # ", PRINT, exec, hyprshot -m region"
    ", Print, exec, ${screenshot} ri"
    "SUPER, Print, exec, ${screenshot} rf"
    "CTRL, Print, exec, ${screenshot} rc"
    "SHIFT, Print, exec, ${screenshot} sc"
    "SUPER SHIFT, Print, exec, ${screenshot} sf"
    "CTRL SHIFT, Print, exec, ${screenshot} si"
    "ALT, Print, exec, ${screenshot} p"

    # Scroll through existing workspaces with mainMod + scroll
    "SUPER, mouse_down, workspace, e+1"
    "SUPER, mouse_up, workspace, e-1"

    # Navigation existing workspaces (don't wrap-around)
    "SUPER ALT, left, workspace, -1"
    "SUPER ALT, right, workspace, +1"
  ];

  binde = [
    "SUPER ALT, H, exec, ${moveWindowOrGroupOrActive} l -40 0"
    "SUPER ALT, J, exec, ${moveWindowOrGroupOrActive} d 0 40"
    "SUPER ALT, K, exec, ${moveWindowOrGroupOrActive} u 0 -40"
    "SUPER ALT, L, exec, ${moveWindowOrGroupOrActive} r 40 0"

    # Resize window
    "SUPER SHIFT, H, resizeactive, -80 0"
    "SUPER SHIFT, J, resizeactive, 0 80"
    "SUPER SHIFT, K, resizeactive, 0 -80"
    "SUPER SHIFT, L, resizeactive, 80 0"

    # Cycle floating windows
    "SUPER, U, cyclenext, floating"
    "SUPER SHIFT, U, cyclenext, prev floating"

    # Screen brightness
    ", XF86MonBrightnessUp,exec,brightnessctl set +5%"
    ", XF86MonBrightnessDown,exec,brightnessctl set 5%-"

    # Volume control
    ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
    ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
  ];

  bindm = [
    # Move/resize windows with mainMod + LMB/RMB and dragging
    "SUPER, mouse:272, movewindow"
    "SUPER, mouse:273, resizewindow"
    "SUPERSHIFT, mouse:272, resizewindow"
    "SUPER ALT, mouse:272, resizewindow"
  ];

}
