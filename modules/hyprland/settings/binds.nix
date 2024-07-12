{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) getExe mkDefault mkIf mkShellScript; 

  cycleFloatingPositions = mkShellScript {
    inputs = with pkgs; [ coreutils hyprland jq ]; text = ''
      is_floating="$(hyprctl activewindow -j | jq -r .floating)"
      if [[ "$is_floating" == "true" ]]; then

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

      fi
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

  # toggleMoveMode = mkShellScript {
  #   inputs = with pkgs; [ coreutils hyprland ]; text = ''
  #     if [[ -e /tmp/movemode ]]; then 
  #       hyprctl keyword unbind , mouse:272
  #       hyprctl keyword unbind , mouse:273
  #       hyprctl keyword unbind , mouse:274
  #       rm -f /tmp/movemode
  #     else
  #       hyprctl keyword bindm , mouse:272, movewindow
  #       hyprctl keyword bindm , mouse:273, resizewindow
  #       hyprctl keyword bind , mouse:274, exec, ${toggleGroupOrLock}
  #       touch /tmp/movemode
  #     fi
  #   '';
  # };

in {

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {

      bind = [

        # Exit hyprland
        "super+shift, q, exit,"

        # Both q and w kill the active window, but some programs override super+w to kill the current tab
        "super, q, killactive,"
        "super, w, killactive,"

        # Manage special workspace
        "super, escape, togglespecialworkspace"
        # "super+alt, escape, movetoworkspacesilent, special"

        # Terminal
        "super, return, exec, kitty"

        # File manager
        "super, e, exec, nautilus"

        # Password manager
        "super, period, exec, 1password"

        # Browser
        "super, b, exec, firefox"
        "super+shift, b, exec, firefox --private-window"

        # Alt browser
        "super+alt, b, exec, chromium-browser"
        "super+alt+shift, b, exec, chromium-browser --incognito"

        # Navigate workspaces
        "super, right, workspace, m+1" # cyclenext
        "super, left, workspace, m-1" # cyclenext, prev

      ] ++ ( 

        let supertab = mkShellScript { 
          inputs = with pkgs; [ hyprland gawk ]; 
          text = ../bin/supertab.sh; 
        }; 

      in [

        # Navigation windows with super tab
        "super, tab, exec, ${supertab}"
        "super+alt, tab, exec, ${supertab} next"
        "super+shift, tab, exec, ${supertab} prev"

        # Back-and-forth with super \
        "super, backslash, focuscurrentorlast"

        # Focus urgent windows
        "super, u, focusurgentorlast"

      ]) ++ [


        # Manage windows
        "super, i, togglesplit"
        "super, i, exec, ${cycleFloatingPositions}"
        "super+shift, i, exec, ${cycleFloatingPositions} reverse"
        "super+shift, p, pseudo"
        "super+shift, p, pin"
        "super, f, fullscreen, 1"
        "super+alt, f, fullscreen, 0"

        # App launcher
        # "super, space, exec, ${getExe pkgs.fuzzel}"

        # Move focus with super [hjkl]
        "super, h, movefocus, l"
        "super, j, movefocus, d"
        "super, k, movefocus, u"
        "super, l, movefocus, r"

        # Switch workspaces with super [0-9]
        "super, 1, workspace, 1"
        "super, 2, workspace, 2"
        "super, 3, workspace, 3"
        "super, 4, workspace, 4"
        "super, 5, workspace, 5"
        "super, 6, workspace, 6"
        "super, 7, workspace, 7"
        "super, 8, workspace, 8"
        "super, 9, workspace, 9"
        "super, 0, workspace, 10"

        # Move active window to a workspace with super+alt [0-9]
        "super+alt, 1, movetoworkspace, 1"
        "super+alt, 2, movetoworkspace, 2"
        "super+alt, 3, movetoworkspace, 3"
        "super+alt, 4, movetoworkspace, 4"
        "super+alt, 5, movetoworkspace, 5"
        "super+alt, 6, movetoworkspace, 6"
        "super+alt, 7, movetoworkspace, 7"
        "super+alt, 8, movetoworkspace, 8"
        "super+alt, 9, movetoworkspace, 9"
        "super+alt, 0, movetoworkspace, 10"

        # Resize active window to various presets
        "super+shift, 1, resizeactive, exact 10% 10%"
        "super+shift, 1, centerwindow, 1"
        "super+shift, 2, resizeactive, exact 20% 20%"
        "super+shift, 2, centerwindow, 1"
        "super+shift, 3, resizeactive, exact 30% 30%"
        "super+shift, 3, centerwindow, 1"
        "super+shift, 4, resizeactive, exact 40% 40%"
        "super+shift, 4, centerwindow, 1"
        "super+shift, 5, resizeactive, exact 50% 50%"
        "super+shift, 5, centerwindow, 1"
        "super+shift, 6, resizeactive, exact 60% 60%"
        "super+shift, 6, centerwindow, 1"
        "super+shift, 7, resizeactive, exact 70% 70%"
        "super+shift, 7, centerwindow, 1"
        "super+shift, 8, resizeactive, exact 80% 80%"
        "super+shift, 8, centerwindow, 1"
        "super+shift, 9, resizeactive, exact 90% 90%"
        "super+shift, 9, centerwindow, 1"

        "super+shift, 0, centerwindow, 1"
        "super+shift, O, resizeactive, exact 600 400"

        # "super+alt, y, centerwindow, 1"
        # "super+alt, i, exec, ${cycleFloatingPositions}"
        # "super+alt+shift, I, exec, ${cycleFloatingPositions} reverse"

        # Super+m to minimize window, Super+m to bring it back (possibly on a different workspace)
        "super, m, togglespecialworkspace, mover"
        "super, m, movetoworkspace, +0"
        "super, m, togglespecialworkspace, mover"
        "super, m, movetoworkspace, special:mover"
        "super, m, togglespecialworkspace, mover"

        # Screenshot a region
        ", print, exec, ${screenshot} ri"
        "super, print, exec, ${screenshot} rf"
        "ctrl, print, exec, ${screenshot} rc"
        "shift, print, exec, ${screenshot} sc"
        "super+shift, print, exec, ${screenshot} sf"
        "ctrl+shift, print, exec, ${screenshot} si"
        "alt, print, exec, ${screenshot} p"

        # Scroll through existing workspaces with super + scroll
        "super, mouse_down, workspace, e+1"
        "super, mouse_up, workspace, e-1"

        # # Experimental
        # "super, f6, exec, ${toggleMoveMode}"
        # "shift, f6, exec, ${toggleMoveMode}"
        # "alt, f6, exec, ${toggleMoveMode}"
      ];

      binde = [

        # Move window 
        "super+alt, h, exec, ${moveWindowOrGroupOrActive} l -40 0"
        "super+alt, j, exec, ${moveWindowOrGroupOrActive} d 0 40"
        "super+alt, k, exec, ${moveWindowOrGroupOrActive} u 0 -40"
        "super+alt, l, exec, ${moveWindowOrGroupOrActive} r 40 0"

        # Resize window
        "super+shift, h, resizeactive, -80 0"
        "super+shift, j, resizeactive, 0 80"
        "super+shift, k, resizeactive, 0 -80"
        "super+shift, l, resizeactive, 80 0"

        # Cycle floating windows
        # "super, y, cyclenext, floating"
        # "super+shift, y, cyclenext, prev floating"

      ];

      bindm = [

        # Move/resize windows with super + LMB/RMB and dragging
        "super, mouse:272, movewindow"
        "super, mouse:273, resizewindow"

      ];

    };
  };

}
