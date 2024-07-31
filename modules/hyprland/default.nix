# programs.hyprland.enable = true;
{ config, lib, pkgs, inputs, ... }: let 

  cfg = config.programs.hyprland;
  inherit (lib) getExe ls mkIf;
  nvidia = config.hardware.nvidia.modesetting.enable; # true if using nvidia

in {

  imports = ls ./. ++ 

    # Flake nixos module
    # https://github.com/hyprwm/Hyprland/blob/main/nix/module.nix
    [ inputs.hyprland.nixosModules.default ];

  config = mkIf cfg.enable {

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

    # # Encourage Wayland support for electron (if not using nvidia)
    # environment.sessionVariables = if nvidia then {} else {
    #   NIXOS_OZONE_WL = "1";
    # };
    environment.sessionVariables.NIXOS_OZONE_WL = "1"; # just do this for all

    # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
    # > XDPH doesn’t implement a file picker. For that, I recommend installing xdg-desktop-portal-gtk alongside XDPH.
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # https://www.reddit.com/r/NixOS/comments/199dm3j/how_do_i_retain_nextcloud_session_on_hyprland/
    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true; # gui to manage keyring

    # https://aylur.github.io/ags-docs/config/utils/#authentication
    security.pam.services.ags = {};

  };

}
