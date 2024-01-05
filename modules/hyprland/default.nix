# modules.hyprland.enable = true;
{ config, lib, pkgs, inputs, this, ... }: 

let 
  cfg = config.modules.hyprland;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (this.lib) destabilize;

  # Unstable nixos hyprland module
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/hyprland.nix
  module = destabilize inputs.unstable "programs/hyprland.nix";

in {

  # Import unstable module
  imports = module ++ [];

  options.modules.hyprland = {
    enable = lib.options.mkEnableOption "hyprland"; 
  };

  config = mkIf cfg.enable {

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    programs.light.enable = true;

    # Enable sound.
    sound.enable = true;
    services.pipewire.enable = true;

    # # Enable audio
    # sound.enable = true;
    # services.pipewire = {
    #   enable = true;
    #   alsa.enable = true;
    #   alsa.support32Bit = true;
    #   pulse.enable = true;
    #   wireplumber.enable = true;
    # };

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
        lightdm.enable = true;
        # gdm = {
        #   enable = true;
        #   wayland = true;
        # };
      };
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs; [
      alsa-utils # provides amixer/alsamixer/...
      mpd # for playing system sounds
      mpc-cli # command-line mpd client
      ncmpcpp # a mpd client with a UI
      networkmanagerapplet # provide GUI app: nm-connection-editor
      wl-clipboard
    ];


    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      # extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    };

    # fix https://github.com/ryan4yin/nix-config/issues/10
    security.pam.services.swaylock = {};

  };

}
