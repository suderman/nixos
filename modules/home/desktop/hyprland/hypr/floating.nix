{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Focus floating windows in workspace
      "super+shift, o, cyclenext, floating"

      # Set window to floating (and also resize if was tiled)
      "super, o, exec, hypr-float"

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
      # If o key held down, pin floating window
      "super, o, pin"

      # Run script again if o key held down
      "super+alt, o, exec, hypr-floatorcycle"
      "super+alt+shift, o, exec, hypr-floatorcycle reverse"
    ];

    binde = [
      # Cycle floating window's position around screen
      "super+alt, o, exec, hypr-floatorcycle"
      "super+alt+shift, o, exec, hypr-floatorcycle reverse"
    ];

    windowrule = [
      # Pinned windows have a border and hide decorations when inactive
      "border_size 2, match:pin 1"
      "decorate 0, match:pin 1, match:focus 0"

      # Picture-in-Picture for any windows tagged "pip"
      "float on, pin on, keep_aspect_ratio on, size 480 270, min_size 240 135, max_size 960 540, move ((monitor_w*1)-490) ((monitor_h*1)-280), match:tag pip"

      # Dialog rules for any windows tagged "dialog"
      "float on, center on, border_size 0, size 1280 768, match:tag dialog"

      # Aways tag these windows as "dialog"
      "tag +dialog, match:title (Progress|Save File|Save As)"
      "tag +dialog, match:class (xdg-desktop-portal-gtk)"
      "tag +dialog, match:class (re.sonny.Junction)"

      # Picture, video, audio overlay for any windows tagged "media"
      "float on, size 1280 720, match:tag media"
    ];
  };
}
