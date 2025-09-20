{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf; 

in {

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {

      bind = [

        # Exit hyprland
        "super+shift, q, exit,"

        # Kill the active window
        "super, w, killactive,"

        # Terminal
        "super, return, exec, kitty"

        # File manager
        "super, e, exec, nautilus"

        # Password manager
        "super+control, period, exec, 1password"

        # Browser
        "super, b, exec, chromium-browser"
        "super+shift, b, exec, chromium-browser --incognito"

        # Alt browser
        "super+alt, b, exec, firefox"
        "super+alt+shift, b, exec, firefox --private-window"

        # Navigate workspaces
        "super, right, workspace, e+1" # cyclenext
        "super, apostrophe, workspace, e+1"
        "super, left, workspace, e-1" # cyclenext, prev
        "super, semicolon, workspace, e-1"


        # Navigation windows with super tab
        "super, tab, exec, hypr-supertab"
        "super+alt, tab, exec, hypr-supertab next"
        "super+shift, tab, exec, hypr-supertab prev"

        # Back-and-forth with super \
        "super, backslash, focuscurrentorlast"

        # Focus urgent windows
        "super, u, focusurgentorlast"


        # Manage windows
        "super, i, togglesplit"
        "super, i, exec, hypr-cyclefloatingpos"
        "super+shift, i, exec, hypr-cyclefloatingpos reverse"
        "super+shift, p, pseudo"
        "super+shift, p, pin"

        # "super+shift, f, fullscreen, 1"
        # "super+alt, f, fullscreen, 2"

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
        # "super, 0, workspace, 10"

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
        # "super+alt, 0, movetoworkspace, 10"

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

        # Super+m to minimize window, Super+m to bring it back (possibly on a different workspace)
        "super, m, togglespecialworkspace, mover"
        "super, m, movetoworkspace, +0"
        "super, m, togglespecialworkspace, mover"
        "super, m, movetoworkspace, special:mover"
        "super, m, togglespecialworkspace, mover"

        # Screenshot a region
        ", print, exec, hypr-screenshot ri"
        "super, print, exec, hypr-screenshot rf"
        "ctrl, print, exec, hypr-screenshot rc"
        "shift, print, exec, hypr-screenshot sc"
        "super+shift, print, exec, hypr-screenshot sf"
        "ctrl+shift, print, exec, hypr-screenshot si"
        "alt, print, exec, hypr-screenshot p"

        # Scroll through existing workspaces with super + scroll
        "super, mouse_down, workspace, e+1"
        "super, mouse_up, workspace, e-1"

      ];

      binde = [

        # Move window 
        "super+alt, h, exec, hypr-movewindoworgrouporactive l -40 0"
        "super+alt, j, exec, hypr-movewindoworgrouporactive d 0 40"
        "super+alt, k, exec, hypr-movewindoworgrouporactive u 0 -40"
        "super+alt, l, exec, hypr-movewindoworgrouporactive r 40 0"

        # Resize window
        "super+shift, h, resizeactive, -80 0"
        "super+shift, j, resizeactive, 0 80"
        "super+shift, k, resizeactive, 0 -80"
        "super+shift, l, resizeactive, 80 0"

      ];

      bindm = [

        # Move/resize windows with super + LMB/RMB and dragging
        "super, mouse:272, movewindow"
        "super, mouse:273, resizewindow"

      ];

    };
  };

}
