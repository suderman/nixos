{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Terminal
      "super, return, exec, kitty"

      # File manager
      "super, y, exec, kitty --class Yazi yazi"

      # Alt file manager
      "super+alt, y, exec, nautilus --new-window"

      # Text editor
      "super, e, exec, kitty --class Neovim nvim"

      # Alt text editor
      "super+alt, e, exec, neovide --neovim-bin nvim"

      # Browser
      "super, b, exec, chromium-browser"
      "super+shift, b, exec, chromium-browser --incognito"

      # Alt browser
      "super+alt, b, exec, firefox"
      "super+alt+shift, b, exec, firefox --private-window"

      # Password manager
      "super+control, period, exec, 1password"
    ];

    # Toggle floating on these launcher keybinds if held down
    bindo = [
      "super, return, exec, hypr-float"
      "super, y, exec, hypr-float"
      "super, e, exec, hypr-float"
      "super, b, exec, hypr-float"
      "super+alt, return, exec, hypr-float"
      "super+alt, y, exec, hypr-float"
      "super+alt, e, exec, hypr-float"
      "super+alt, b, exec, hypr-float"
    ];
  };
}
