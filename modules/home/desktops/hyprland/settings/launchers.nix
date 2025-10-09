{...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Terminal
      "super, return, exec, kitty"

      # File manager
      "super, y, exec, kitty yazi"

      # Alt file manager
      "super+alt, y, exec, nautilus --new-window"

      # Text editor
      "super, e, exec, kitty nvf"

      # Alt text editor
      "super+alt, e, exec, neovide --neovim-bin nvf"

      # Browser
      "super, b, exec, chromium-browser"
      "super+shift, b, exec, chromium-browser --incognito"

      # Alt browser
      "super+alt, b, exec, firefox"
      "super+alt+shift, b, exec, firefox --private-window"

      # Password manager
      "super+control, period, exec, 1password"
    ];
  };
}
