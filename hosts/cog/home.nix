# This is your home-manager configuration file
{ inputs, outputs, host, lib, config, pkgs, ... }: {

  imports = [
    ../../home
    ../../home/cli
    ../../home/gui
  ];

  xdg.desktopEntries = {
    code = {
      name = "Visual Studio Code";
      genericName = "Text Editor";
      terminal = false;
      categories = [ "Utility" "TextEditor" "Development" "IDE" ];
      mimeType = [ "text/plain" "inode/directory" ];
      icon = "code";
      exec = "code --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland";
    };

    webcord = {
      name = "Webcord";
      genericName = "Discord and Fosscord client";
      terminal = false;
      categories = [ "Network" "InstantMessaging" ];
      mimeType = [ "x-scheme-handler/discord" ];
      icon = "webcord";
      exec = "webcord --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland";
    };
  };
  
  programs = {
    neovim.enable = true;
    chromium = {
      enable = true;
      commandLineArgs = [ "--enable-features=UseOzonePlatform" "-ozone-platform=wayland" "--gtk-version=4" ];
    };
  };



  home.packages = with pkgs;
  let
      zulipWayland = pkgs.makeDesktopItem {
        name = "zulip-wayland";
        desktopName = "Zulip (Wayland)";
        exec = "${zulip}/bin/zulip --enable-features=UseOzonePlatform --ozone-platform=wayland";
        terminal = false;
        icon = "zulip";
        type = "Application";
      };
      # Facebook messenger
      fbChromeDesktopItem = pkgs.makeDesktopItem {
        name = "messenger-chrome";
        desktopName = "Messenger (chrome)";
        exec = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform -ozone-platform=wayland \"--app=https://messenger.com\"";
        terminal = false;
      };
      # Teams
      teamsItem = pkgs.makeDesktopItem {
        name = "teams-wayland";
        desktopName = "Teams (Wayland)";
        exec = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform -ozone-platform=wayland \"--app=https://teams.microsoft.com\"";
        terminal = false;
      };
      # Cinny
      cinnyItem = pkgs.makeDesktopItem {
        name = "cinny";
        desktopName = "Cinny";
        exec = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform -ozone-platform=wayland \"--app=https://app.cinny.in\"";
        terminal = false;
      };
    in
      [
        nur.repos.mic92.hello-nur
        # Desktop matrix client
        # (lib.enableWayland element-desktop "element-desktop")
        (me.enableWayland element-desktop "element-desktop")
        # Desktop signal client
        (me.enableWayland signal-desktop "signal-desktop")
        # Desktop telegram client
        tdesktop
        # # Desktop mastodon client
        # # tootle
        # # zulip
        # zulip
        # zulipWayland
        # # Zoom (for work, sadly)
        zoom-us
        # # Teams (also for work)
        # teams
        # # Cinny for pretty matrix
        # cinnyItem
        # chromium
        # (lib.enableWayland chromium "chromium")
        # Wayland workaround packages
        fbChromeDesktopItem
        teamsItem
        newsflash
        # me.obsidian
        (me.enableWayland slack "slack")
        # (me.enableWayland vscodium "codiuim")
        # vscodium
        unstable.sl
        
        # my script
        yo

        # signal-desktop
        nnn 
        owncloud-client
        # slack
        _1password
        (me.enableWayland _1password-gui "1password")
        # nur.repos.mic92.hello-nur
        # owofetch
        # firefox
        firefox-wayland
        # junction
        # # chromium
        # # element
        # plexamp
        (me.enableWayland plexamp "plexamp")
        # # element-desktop
        # obsidian
        # discord
        xorg.xeyes
        nur.repos.arc.packages.mpd-youtube-dl
        # # neovim
      ];


  # home.file = { 
  #   ".emacs.d/init.el".source = config.lib.file.mkOutOfStoreSymlink ./init.el;
  #   ".emacs.d/early-init.el".source = config.lib.file.mkOutOfStoreSymlink ./early-init.el; 
  # };
  # xdg.configFile."btop/btop.conf".source = ../../config/btop/btop.conf;
  # xdg.configFile."hostname.txt".text = "The hostname is ${host.hostname}";


  xdg.configFile = let flags = ''
    --enable-features=UseOzonePlatform 
    --ozone-platform=wayland
    '';
  in {
    "chromium-flags.conf".text = flags;
    "electron-flags.conf".text = flags;
    "electron-flags16.conf".text = flags;
    "electron-flags17.conf".text = flags;
    "electron-flags18.conf".text = flags;
    "electron-flags19.conf".text = flags;
  };


  # home.file.".config/"
  # xdg.configFile."i3blocks/config".source = ./i3blocks.conf;
  # home.file.".gdbinit".text = ''
  #     set auto-load safe-path /nix/store
  # '';

}
