{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Toggle floating on active window
      "super, o, exec, hypr-togglefloating"
      "super+shift, o, cyclenext, floating"
    ];

    # Toggle floating on these launcher keybind if held down
    bindo = [
      "super, return, exec, hypr-togglefloating"
      "super, y, exec, hypr-togglefloating"
      "super, e, exec, hypr-togglefloating"
      "super, b, exec, hypr-togglefloating"
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
