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

in {

  bind = [
    "SUPER, Return, exec, kitty"
    "SUPER, W, killactive,"
    "SUPERSHIFT, Q, exit,"
    "SUPER, E, exec, nautilus"
    "SUPER, F, exec, firefox"

    "SUPER, Escape, togglespecialworkspace"
    "SUPER ALT, Escape, movetoworkspacesilent, special"

    # "SUPER, Tab, cyclenext,"
    # "SUPER SHIFT, Tab, cyclenext, prev"
    "SUPER, Tab, workspace, m+1"
    "SUPER SHIFT, Tab, workspace, m-1"

    "SUPER, Backslash, workspace, previous"

    "SUPER, bracketleft, workspace, -1"
    "SUPER, bracketright, workspace, +1"

    "SUPER ALT, G,  togglegroup,"
    "SUPER, G, exec, ${toggleGroupOrLock}"
    "SUPER, N, changegroupactive, f"
    "SUPER SHIFT, N, changegroupactive, b"

    "SUPER, I, togglesplit"
    "SUPER, P, pseudo"
    "SUPER, O, togglefloating"
    "SUPER, P, pin"
    "SUPER, Z, fullscreen, 1"
    "SUPER ALT, Z, fullscreen, 0"

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

    "SUPER SHIFT, 1, movewindow, u"
    "SUPER SHIFT, 1, movewindow, l"
    "SUPER SHIFT, 2, movewindow, u"
    "SUPER SHIFT, 2, movewindow, r"
    "SUPER SHIFT, 3, movewindow, d"
    "SUPER SHIFT, 3, movewindow, l"
    "SUPER SHIFT, 4, movewindow, d"
    "SUPER SHIFT, 4, movewindow, r"
    "SUPER SHIFT, 4, movewindow, r"

    "SUPER SHIFT, 0, centerwindow, 1"
    "SUPER SHIFT, O, resizeactive, exact 600 400"

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

    "SUPER SHIFT, H, resizeactive, -80 0"
    "SUPER SHIFT, J, resizeactive, 0 80"
    "SUPER SHIFT, K, resizeactive, 0 -80"
    "SUPER SHIFT, L, resizeactive, 80 0"

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
