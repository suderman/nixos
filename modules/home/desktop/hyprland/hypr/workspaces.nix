{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Navigate workspaces with super left/right
      "super, left, exec, hypr-workspace prev"
      "super, right, exec, hypr-workspace next"
      # "super, left, workspace, e-1" # cyclenext, prev
      # "super, right, workspace, e+1" # cyclenext

      # Also navigate workspaces with super semicolon/apostrophone (hhkb arrows)
      "super, semicolon, exec, hypr-workspace prev"
      "super, apostrophe, exec, hypr-workspace next"
      # "super, semicolon, workspace, e-1"
      # "super, apostrophe, workspace, e+1"

      # Scroll through existing workspaces with super + scroll
      "super, mouse_down, exec, hypr-workspace prev"
      "super, mouse_up, exec, hypr-workspace next"
      # "super, mouse_down, workspace, e+1"
      # "super, mouse_up, workspace, e-1"

      "super+alt, mouse_down, layoutmsg, move -col"
      "super+alt, mouse_up, layoutmsg, move +col"

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

      "super+alt, p, exec, hypr-workspace prev"
      "super+alt, n, exec, hypr-workspace next"

      # Cycle through layouts with super+alt n
      # dwindle > master > scrolling > monocle
      # "super+alt, n, exec, hypr-cyclelayout next"
      "super, slash, exec, hypr-cyclelayout next"
      # Reverse the cycle with super+alt p
      # "super+alt, p, exec, hypr-cyclelayout prev"
      "super+alt, slash, exec, hypr-cyclelayout prev"
    ];

    # Cycle through windows with with super n/p
    binde = [
      "super, n, exec, hypr-nextprev next"
      "super, p, exec, hypr-nextprev prev"
    ];

    windowrule = [
      # Games fullscreen on workspace 9
      "workspace 9, fullscreen on, match:tag game"

      # idle inhibit while fullscreen (games, videos, etc)
      "idle_inhibit fullscreen, match:class .*"
    ];
  };
}
