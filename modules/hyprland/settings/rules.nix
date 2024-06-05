{ lib, ... }: let inherit (lib) mkDefault; in {

  windowrulev2 = [

    # forbid windows from maximizing/fullscreening themselves
    "suppressevent maximize, class:.*"
    "suppressevent fullscreen, class:.*"

    # idle inhibit while fullscreen (games, videos, etc) 
    "idleinhibit fullscreen, class:.*"

    
    # # make Firefox PiP window small, floating, sticky, and move to bottom right
    # "float, title:^(Picture-in-Picture)$"
    # "pin, title:^(Picture-in-Picture)$"
    # "size 480 270, title:^(Picture-in-Picture)$"
    # "move 100%-490 100%-280, title:(Picture-in-Picture)"

    # make Firefox PiP window small, floating, sticky, and move to bottom right
    "tag +pip, title:^(Picture-in-Picture)$"
    "float, tag:pip"
    "pin, tag:pip"
    "keepaspectratio, tag:pip"
    "noborder, tag:pip"
    "size 480 270, tag:pip"
    "minsize 240 135, tag:pip"
    "maxsize 960 540, tag:pip"
    "move 100%-490 100%-280, tag:pip"


    "tag +pwd, class:(1Password), title:(1Password)$"
    "float, tag:pwd"
    "size 1024 768, tag:pwd"
    # "float, class:(1Password), title:(1Password)$"
    # "size 1024 768, class:(1Password), title:(1Password)"
    # "stayfocused,title:^(Quick Access — 1Password)$"
    # "dimaround,title:^(Quick Access — 1Password)$"
    # "noanim,title:^(Quick Access — 1Password)$"

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

    # 
    "tag +web, class:[Ff]irefox"
    "tag +web2, class:[Cc]hromium-browser"

    # Tag steam and games
    "tag +steam, class:[Ss]team"
    "tag +steam, class:^steam_app_(.*)$"
    "tag +steam, class:^(.*).bin.x86$"

    # Steam and games fullscreen on workspace 10
    "workspace 10, tag:steam"
    "fullscreen, tag:steam"
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

}
