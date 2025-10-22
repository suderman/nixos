{
  lib,
  pkgs,
  flake,
  ...
}: {
  imports = [flake.nixosModules.desktop.default];

  # Set this to a username to automatically login at boot
  options.programs.hyprland.autologin = lib.mkOption {
    type = with lib.types; nullOr str;
    default = null;
  };

  config = {
    # Greeter
    services.displayManager.ly = {
      enable = true;
      settings = {
        clear_password = true;
        vi_mode = false;
        animation = "matrix";
        bigclock = true;
      };
    };
    persist.scratch.files = ["/etc/ly/save.ini"];

    # The one and only
    programs.hyprland.enable = true;

    # Enable screen brightness control
    programs.light.enable = true;

    # https://github.com/ArtsyMacaw/wlogout/issues/61
    programs.gdk-pixbuf.modulePackages = [pkgs.librsvg];

    # Enable audio
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Quick Look
    services.gnome.sushi.enable = true;

    # Thumbnail support for images
    services.tumbler.enable = true;

    environment.systemPackages = with pkgs; [
      alsa-utils # provides amixer/alsamixer/...
      networkmanagerapplet # provide GUI app: nm-connection-editor
      wl-clipboard
      vulkan-tools
    ];

    # Encourage Wayland support for electron
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # https://wiki.hyprland.org/Useful-Utilities/xdg-desktop-portal-hyprland/
    # > XDPH doesn’t implement a file picker. For that, I recommend installing xdg-desktop-portal-gtk alongside XDPH.
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    # https://www.reddit.com/r/NixOS/comments/199dm3j/how_do_i_retain_nextcloud_session_on_hyprland/
    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true; # gui to manage keyring

    # https://home-manager-options.extranix.com/?query=hyprlock&release=release-25.05
    security.pam.services.hyprlock = {};

    # https://home-manager-options.extranix.com/?query=swaylock&release=release-25.05
    security.pam.services.swaylock = {};
  };
}
