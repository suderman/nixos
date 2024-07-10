# programs.hyprland.enable = true;
{ config, lib, pkgs, this, inputs, ... }: 

let 

  cfg = config.programs.hyprland;
  inherit (lib) getExe mkBefore mkDefault mkIf mkOption types;
  nvidia = config.hardware.nvidia.modesetting.enable; # true if using nvidia

in {

  imports = 

    # Flake nixos module
    # https://github.com/hyprwm/Hyprland/blob/main/nix/module.nix
    [ inputs.hyprland.nixosModules.default ];

  # Set this to a username to automatically login at boot
  options.programs.hyprland.autologin = mkOption {
    type = with lib.types; nullOr str;
    default = null;
  };

  config = mkIf cfg.enable {
    programs.light.enable = true;

    # Enable audio
    sound.enable = true;
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

    # Encourage Wayland support for electron (if not using nvidia)
    environment.sessionVariables = if nvidia then {} else {
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs; [
      alsa-utils # provides amixer/alsamixer/...
      mpd # for playing system sounds
      mpc-cli # command-line mpd client
      ncmpcpp # a mpd client with a UI
      networkmanagerapplet # provide GUI app: nm-connection-editor
      wl-clipboard
      vulkan-tools
    ];

    # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
    # > XDPH doesn’t implement a file picker. For that, I recommend installing xdg-desktop-portal-gtk alongside XDPH.
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # https://aylur.github.io/ags-docs/config/utils/#authentication
    security.pam.services.ags = {};

    # Login screen
    services.greetd = let command = getExe pkgs.hyprland; in {
      enable = true;
      settings = {
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


  };

}
