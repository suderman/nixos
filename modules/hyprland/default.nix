# programs.hyprland.enable = true;
{ config, lib, pkgs, this, inputs, ... }: 

let 

  cfg = config.programs.hyprland;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (this.lib) destabilize;

in {

  imports = 

    # Flake nixos module
    # https://github.com/hyprwm/Hyprland/blob/main/nix/module.nix
    [ inputs.hyprland.nixosModules.default ];

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
      vulkan-tools
    ];

    # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
    # > XDPH doesn’t implement a file picker. For that, I recommend installing xdg-desktop-portal-gtk alongside XDPH.
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # https://aylur.github.io/ags-docs/config/utils/#authentication
    security.pam.services.ags = {};

    # # Login screen
    # services = {
    #   # displayManager.defaultSession = "hyprland";
    #   xserver = {
    #     enable = true;
    #     # desktopManager.xterm.enable = false;
    #     displayManager = {
    #       lightdm.enable = true;
    #     };
    #   };
    # };

  };

}
