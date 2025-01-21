# programs.hyprland.enable = true;
{ config, lib, pkgs, ... }: let 

  cfg = config.programs.hyprland;
  inherit (lib) getExe mkIf mkOption types;

in {

  # Set this to a username to automatically login at boot
  options.programs.hyprland.autologin = mkOption {
    type = with lib.types; nullOr str;
    default = null;
  };

  config = mkIf cfg.enable {

    # Login screen
    services.greetd = let command = getExe pkgs.hyprland; in {
      enable = true;
      settings = {
        terminal.vt = 1;
        default_session = {
          user = "greeter";
          command = builtins.toString [ "${getExe pkgs.greetd.tuigreet}"
            "--greeting 'Welcome to NixOS!'" 
            "--asterisks" # display asterisks when a secret is typed
            "--remember" # remember last logged-in username
            "--remember-user-session" # remember last selected session for each user
            "--time" # display the current date and time
            "--cmd ${command}"
          ];
        };
      } // ( if cfg.autologin == null then {} else { 
        initial_session = { 
          user = cfg.autologin;
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


  };

}
