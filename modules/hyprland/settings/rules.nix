{ config, lib, pkgs, ... }: let 

  cfg = config.wayland.windowManager.hyprland;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {

      windowrulev2 = [

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
        "size 480 270, tag:pip"
        "minsize 240 135, tag:pip"
        "maxsize 960 540, tag:pip"
        "move 100%-490 100%-280, tag:pip"

        # make pop-up file dialogs floating, centred, and pinned
        "tag +dialog, title:(Open|Progress|Save File|Save As)"
        "tag +dialog, class:(xdg-desktop-portal-gtk)"
        "float, tag:dialog"
        "center, tag:dialog"
        "pin, tag:dialog"

        # assign windows to workspaces
        # "workspace 1 silent, class:[Ff]irefox"
        # "workspace 0 silent, class:[Ss]team"
        # "workspace 1, class:[Ff]irefox"

        # Tag steam and games
        "tag +steam, class:[Ss]team"
        "tag +steam, class:^steam_app_(.*)$"
        "tag +steam, class:^(.*).bin.x86$"
        "tag +steam, class:^(TurokEx)$"

        # Steam and games fullscreen on workspace 10
        "workspace 10, tag:steam"
        # "fullscreen, tag:steam"
        "rounding 0, tag:steam"
        "noborder, tag:steam"

        # # Steam and games fullscreen on workspace 10
        # "workspace 10, class:[Ss]team"
        # "fullscreen, class:[Ss]team"
        # "workspace 10, class:^steam_app_(.*)$"
        # "fullscreen, class:^steam_app_(.*)$"

        # throw sharing indicators away
        # "workspace special silent, title:^(Firefox — Sharing Indicator)$"
        # "workspace special silent, title:^(.*is sharing (your screen|a window)\.)$"

        "float, class:^(org.telegram.desktop|telegramdesktop)$, title:^(Media viewer)$"

      ];

    };
  };

}
