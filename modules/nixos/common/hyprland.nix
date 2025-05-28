{ config, lib, pkgs, ... }: let

  inherit (builtins) any attrNames toString; 
  inherit (lib) getExe mkIf; 

  # If any hyprland is enabled for any home-manager user,set this to true
  enable = let users = config.home-manager.users or {}; in any 
    ( user: users.${user}.wayland.windowManager.hyprland.enable or false ) 
    ( attrNames users );

  autologin = null;

in {

  # Only enable the nixos module if the home-manager module is enabled
  config = mkIf enable {

    # Login screen
    services.greetd = let command = getExe pkgs.hyprland; in {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          user = "greeter";
          command = toString [ "${getExe pkgs.greetd.tuigreet}"
            "--greeting 'Welcome to NixOS!'" 
            "--asterisks" # display asterisks when a secret is typed
            "--remember" # remember last logged-in username
            "--remember-user-session" # remember last selected session for each user
            "--time" # display the current date and time
            "--cmd ${command}"
          ];
        };
      } // ( if autologin == null then {} else { 
        initial_session = { 
          user = autologin;
          inherit command; 
        };
      } );
    };

    # Extend systemd service
    systemd.services.greetd.serviceConfig = {

      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";

      # Without this errors will spam on screen
      StandardError = "journal"; 

      # Without these bootlogs will spam on screen
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;

    };

    # Enable screen brightness control
    programs.light.enable = true;

    # Enable audio
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Mount, trash, and other functionalities
    services.gvfs.enable = true;

    # Quick Look
    services.gnome.sushi.enable = true;

    # Thumbnail support for images
    services.tumbler.enable = true;

    environment.systemPackages = with pkgs; [
      alsa-utils # provides amixer/alsamixer/...
      mpd # for playing system sounds
      mpc-cli # command-line mpd client
      ncmpcpp # a mpd client with a UI
      networkmanagerapplet # provide GUI app: nm-connection-editor
      wl-clipboard
      vulkan-tools
    ];

    # Encourage Wayland support for electron
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
    # > XDPH doesn’t implement a file picker. For that, I recommend installing xdg-desktop-portal-gtk alongside XDPH.
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # https://www.reddit.com/r/NixOS/comments/199dm3j/how_do_i_retain_nextcloud_session_on_hyprland/
    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true; # gui to manage keyring

    # https://aylur.github.io/ags-docs/config/utils/#authentication
    security.pam.services.ags = {};

    # https://home-manager-options.extranix.com/?query=hyprlock&release=release-24.11
    security.pam.services.hyprlock = {};

    # https://home-manager-options.extranix.com/?query=swaylock&release=release-24.11
    security.pam.services.swaylock = {};

  };

}
