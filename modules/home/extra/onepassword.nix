# programs.onepassword.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.onepassword;
  inherit (lib) mkIf;
  inherit (config.services.keyd.lib) mkClass;

  # Window class name
  class = "1Password";
in {
  options.programs.onepassword = {
    enable = lib.options.mkEnableOption "onepassword";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs._1password-gui pkgs._1password-cli];

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {};

    wayland.windowManager.hyprland.settings = {
      windowrule = [];
    };

    # Persist reboots, skip backups
    persist.scratch.directories = [".config/1Password"];
  };
}
