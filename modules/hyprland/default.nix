# modules.hyprland.enable = true;
{ config, lib, pkgs, inputs, ... }: 

let 
  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkOption mkBefore types;

in {

  # Import hyprland module
  imports = [ inputs.hyprland.nixosModules.default ];

  options.modules.hyprland = {
    enable = lib.options.mkEnableOption "hyprland"; 
  };

  config = mkIf cfg.enable {

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

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

    environment.systemPackages = with pkgs; [
      alsa-utils # provides amixer/alsamixer/...
      mpd # for playing system sounds
      mpc-cli # command-line mpd client
      ncmpcpp # a mpd client with a UI
      networkmanagerapplet # provide GUI app: nm-connection-editor
    ];

    # Mount, trash, and other functionalities
    services.gvfs.enable = true;

    # Thumbnail support for images
    services.tumbler.enable = true;

    # Login screen
    services.xserver = {
      enable = true;
      desktopManager.xterm.enable = false;
      displayManager = {
        defaultSession = "hyprland";
        lightdm.enable = false;
        gdm = {
          enable = true;
          wayland = true;
        };
      };
    };

    # xdg.portal = {
    #   enable = true;
    #   wlr.enable = true;
    #   extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    # };
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # fix https://github.com/ryan4yin/nix-config/issues/10
    security.pam.services.swaylock = {};

  };

}
