{
  pkgs,
  flake,
  ...
}: {
  imports = [flake.nixosModules.desktops.default];

  services = {
    libinput.enable = true; # enable touchpad support
    xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.autoSuspend = true;
    };
    geoclue2.enable = true;
    gnome.games.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      wl-clipboard
    ];

    variables = {
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      NIXOS_OZONE_WL = "1";
    };
  };

  # Enable sound.
  services.pipewire.enable = true;

  # # Gnome has a hard-coded screenshots directory # Watch that directory for screenshots, move contents to new directory and delete old
  # # https://discourse.gnome.org/t/feature-request-change-screenshot-directory/14001/9
  # systemd = let old = "${home}/data/images/Screenshots"; new = "${home}/data/images/screens"; in {
  #
  #   # Watch the "old" path and when it exists, trigger the ssmv service
  #   paths.ssmv = {
  #     wantedBy = [ "paths.target" ];
  #     pathConfig = {
  #       PathExists = old;
  #       Unit = "ssmv.service";
  #     };
  #   };
  #
  #   # Move all files inside the "old" directory into the "new" and delete the "old" directory
  #   services.ssmv = {
  #     description = "Moves files from ${old} to ${new} and deletes ${old}";
  #     requires = [ "ssmv.path" ];
  #     serviceConfig.Type = "oneshot";
  #     script = "mv ${old}/* ${new}/ && rmdir --ignore-fail-on-non-empty ${old}";
  #   };
  #
  # };
}
