{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Navigate workspaces with super left/right
      "super, left, workspace, e-1" # cyclenext, prev
      "super, right, workspace, e+1" # cyclenext

      # Also navigate workspaces with super semicolon/apostrophone (hhkb arrows)
      "super, semicolon, workspace, e-1"
      "super, apostrophe, workspace, e+1"

      # Scroll through existing workspaces with super + scroll
      "super, mouse_down, workspace, e+1"
      "super, mouse_up, workspace, e-1"

      # Switch workspaces with super [1-9]
      "super, 1, workspace, 1"
      "super, 2, workspace, 2"
      "super, 3, workspace, 3"
      "super, 4, workspace, 4"
      "super, 5, workspace, 5"
      "super, 6, workspace, 6"
      "super, 7, workspace, 7"
      "super, 8, workspace, 8"
      "super, 9, workspace, 9"

      # Move active window to a workspace with super+alt [1-9]
      "super+alt, 1, movetoworkspace, 1"
      "super+alt, 2, movetoworkspace, 2"
      "super+alt, 3, movetoworkspace, 3"
      "super+alt, 4, movetoworkspace, 4"
      "super+alt, 5, movetoworkspace, 5"
      "super+alt, 6, movetoworkspace, 6"
      "super+alt, 7, movetoworkspace, 7"
      "super+alt, 8, movetoworkspace, 8"
      "super+alt, 9, movetoworkspace, 9"
    ];

    windowrule = [
      # assign windows to workspaces
      # "workspace 1 silent, class:[Ff]irefox"
      # "workspace 0 silent, class:[Ss]team"
      # "workspace 1, class:[Ff]irefox"

      # Games fullscreen on workspace 9
      # "workspace 9, tag:game"
      # "fullscreen, tag:game"
      "workspace 9, fullscreen on, match:tag game"

      # forbid windows from maximizing/fullscreening themselves
      # "suppressevent maximize, class:.*"
      # "suppressevent fullscreen, class:.*"

      # idle inhibit while fullscreen (games, videos, etc)
      # "idleinhibit fullscreen, class:.*"
      "idle_inhibit fullscreen, match:class .*"
    ];
  };
}
