{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Focus floating windows in workspace
      "super+shift, o, cyclenext, floating"

      # Set window to floating, or pin if already floating
      "super, o, exec, hypr-floatorpin"

      # Resize active window to various presets
      "super+shift, 1, exec, hypr-resizefloating 10"
      "super+shift, 2, exec, hypr-resizefloating 20"
      "super+shift, 3, exec, hypr-resizefloating 30"
      "super+shift, 4, exec, hypr-resizefloating 40"
      "super+shift, 5, exec, hypr-resizefloating 50"
      "super+shift, 6, exec, hypr-resizefloating 60"
      "super+shift, 7, exec, hypr-resizefloating 70"
      "super+shift, 8, exec, hypr-resizefloating 80"
      "super+shift, 9, exec, hypr-resizefloating 90"
    ];

    bindo = [
      # Run script again if o key held down
      "super, o, exec, hypr-floatorpin"
      "super+alt, o, exec, hypr-floatorcycle"
      "super+alt+shift, o, exec, hypr-floatorcycle reverse"

      # Toggle floating on these launcher keybinds if held down
      "super, return, exec, hypr-floatorpin"
      "super, y, exec, hypr-floatorpin"
      "super, e, exec, hypr-floatorpin"
      "super, b, exec, hypr-floatorpin"
      "super+alt, return, exec, hypr-floatorpin"
      "super+alt, y, exec, hypr-floatorpin"
      "super+alt, e, exec, hypr-floatorpin"
      "super+alt, b, exec, hypr-floatorpin"
    ];

    binde = [
      # Cycle floating window's position around screen
      "super+alt, o, exec, hypr-floatorcycle"
      "super+alt+shift, o, exec, hypr-floatorcycle reverse"
    ];

    windowrule = [
      # Pinned windows have a border and hide decorations when inactive
      "bordersize 2, pinned:1"
      "decorate 0, pinned:1 focus:0"

      # Picture-in-Picture for any windows tagged "pip"
      # ("tag +pip" rules are found elsewhere)
      "float, tag:pip"
      "pin, tag:pip"
      "keepaspectratio, tag:pip"
      "size 480 270, tag:pip"
      "minsize 240 135, tag:pip"
      "maxsize 960 540, tag:pip"
      "move 100%-490 100%-280, tag:pip"

      # Dialog rules for any windows tagged "dialog"
      "float, tag:dialog"
      "center, tag:dialog"
      "noborder, tag:dialog"
      "size 1280 768, tag:dialog"

      # Aways tag these windows as "dialog"
      "tag +dialog, title:(Progress|Save File|Save As)"
      "tag +dialog, class:(xdg-desktop-portal-gtk)"
      "tag +dialog, class:(re.sonny.Junction)"

      # Picture, video, audio overlay for any windows tagged "media"
      # ("tag +pip" rules are found elsewhere)
      "float, tag:media"
      "size 1280 720, tag:media"
    ];
  };
}
