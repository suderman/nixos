{...}: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # forbid windows from maximizing/fullscreening themselves
      "suppressevent maximize, class:.*"
      "suppressevent fullscreen, class:.*"

      # idle inhibit while fullscreen (games, videos, etc)
      "idleinhibit fullscreen, class:.*"

      # Picture-in-Picture for any windows tagged pip
      "float, tag:pip"
      "pin, tag:pip"
      "keepaspectratio, tag:pip"
      "noborder, tag:pip"
      "plugin:hyprbars:nobar, tag:pip"
      "size 480 270, tag:pip"
      "minsize 240 135, tag:pip"
      "maxsize 960 540, tag:pip"
      "move 100%-490 100%-280, tag:pip"

      # make pop-up file dialogs floating, centred, and pinned
      "tag +dialog, title:(Progress|Save File|Save As)"
      # "tag +dialog, title:(Open|Progress|Save File|Save As)"
      "tag +dialog, class:(xdg-desktop-portal-gtk)"
      "tag +dialog, class:(re.sonny.Junction)"
      "float, tag:dialog"
      "center, tag:dialog"
      "pin, tag:dialog"
      "noborder, tag:dialog"
      "plugin:hyprbars:nobar, tag:dialog"

      "float, tag:media"
      "size 1280 720, tag:media"

      # assign windows to workspaces
      # "workspace 1 silent, class:[Ff]irefox"
      # "workspace 0 silent, class:[Ss]team"
      # "workspace 1, class:[Ff]irefox"
    ];
  };
}
