{ lib, ... }: let inherit (lib) mkDefault; in {

  bind = [
    "SUPER, Return, exec, kitty"
    "SUPER, Q, killactive,"
    "SUPERSHIFT, Q, exit,"
    "SUPER, E, exec, nautilus"
    "SUPER, F, exec, firefox"
    "SUPER ALT, z, togglefloating"
    "SUPER, z, fullscreen"

    "SUPER, Escape, togglespecialworkspace"
    "SUPER ALT, Escape, movetoworkspacesilent, special"

    # "numlock, exec, sleep 1 && hyprctl dispatch dpms off"
    # "f9, exec, sleep 1 && hyprctl dispatch dpms off"
    # "f10, exec, sleep 1 && hyprctl dispatch dpms on"

    "SUPER, Space, exec, tofi-drun --drun-launch=true"
    "SUPER, N, layoutmsg, swapnext"
    "SUPER, P, layoutmsg, swapprev"
    "SUPER, B, layoutmsg, swapwithmaster master"
    "SUPER, G, layoutmsg, addmaster "
    "SUPER+SHIFT, G, layoutmsg, removemaster"

    # Move focus with mainMod + arrow keys
    "SUPER, H, movefocus, l"
    "SUPER, J, movefocus, d"
    "SUPER, K, movefocus, u"
    "SUPER, L, movefocus, r"

    "SUPERSHIFTCONTROL, J, layoutmsg, swapnext"
    "SUPERSHIFTCONTROL, K, layoutmsg, swapprev"
    "SUPER, M, layoutmsg, swapwithmaster master"

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

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    "SUPER SHIFT, 1, movetoworkspace, 1"
    "SUPER SHIFT, 2, movetoworkspace, 2"
    "SUPER SHIFT, 3, movetoworkspace, 3"
    "SUPER SHIFT, 4, movetoworkspace, 4"
    "SUPER SHIFT, 5, movetoworkspace, 5"
    "SUPER SHIFT, 6, movetoworkspace, 6"
    "SUPER SHIFT, 7, movetoworkspace, 7"
    "SUPER SHIFT, 8, movetoworkspace, 8"
    "SUPER SHIFT, 9, movetoworkspace, 9"
    "SUPER SHIFT, 0, movetoworkspace, 10"

    # Scroll through existing workspaces with mainMod + scroll
    "SUPER, mouse_down, workspace, e+1"
    "SUPER, mouse_up, workspace, e-1"

    # Navigation existing workspaces (don't wrap-around)
    "SUPER ALT, left, workspace, -1"
    "SUPER ALT, right, workspace, +1"
    "SUPER, comma, workspace, -1"
    "SUPER, period, workspace, +1"
  ];

  binde = [
    "SUPERSHIFT, H, resizeactive, -80 0"
    "SUPERSHIFT, J, resizeactive, 0 80"
    "SUPERSHIFT, K, resizeactive, 0 -80"
    "SUPERSHIFT, L, resizeactive, 80 0"

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
