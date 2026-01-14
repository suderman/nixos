# programs.onepassword.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.onepassword;
  inherit (lib) mkIf;
  inherit (config.lib.keyd) mkClass;

  # Window class name
  class = "1Password";
in {
  options.programs.onepassword = {
    enable = lib.options.mkEnableOption "onepassword";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs._1password-gui pkgs._1password-cli];

    # Float and resize
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        # Main window
        # "tag +pwd, class:(1Password), title:^(1Password)$"
        # "float, tag:pwd"
        # "size 1024 768, tag:pwd"
        "tag +pwd, match:class (1Password), match:title ^(1Password)$"
        "float on, size 1024 768, match:tag pwd"

        # Dialog window
        # "tag +pwd_dialog, class:(1Password), title:^(.*)Password — 1Password$"
        # "float, tag:pwd_dialog"
        # "size 1280 240, tag:pwd_dialog"
        # "center, tag:pwd_dialog"
        # "pin, tag:pwd_dialog"
        "tag +pwd_dialog, match:class (1Password), match:title ^(.*)Password — 1Password$"
        "float on, size 1280 240, center on, pin on, match:tag pwd_dialog"
      ];
    };

    # keyboard shortcuts
    services.keyd.windows."${mkClass class}" = {
      "esc" = "C-w";
    };

    # Persist reboots, skip backups
    persist.scratch.directories = [".config/1Password"];
  };
}
