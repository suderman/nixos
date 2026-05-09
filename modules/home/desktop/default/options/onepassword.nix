# programs.onepassword.enable = true;
{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.programs.onepassword;
  inherit (lib) mkIf;
  inherit (config.lib.keyd) mkClass;

  # Window class name
  class = "1Password";
  hasHyprLua = lib.hasAttrByPath ["wayland" "windowManager" "hyprland" "lua" "features"] options;
in {
  options.programs.onepassword = {
    enable = lib.options.mkEnableOption "onepassword";
  };

  config = mkIf cfg.enable (lib.mkMerge [
    {
    home.packages = [pkgs._1password-gui pkgs._1password-cli];

    # Float and resize
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        # Main window
        "tag +pwd, match:class (1Password), match:title ^(1Password)$"
        "float on, size 1024 768, match:tag pwd"

        # Dialog window
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
    }
    (lib.optionalAttrs hasHyprLua {
      wayland.windowManager.hyprland.lua.features.onepassword = ''
        hl.window_rule({
            name = "onepassword-main-tag",
            match = { class = "${class}", title = "^(1Password)$" },
            tag = "+pwd",
        })
        hl.window_rule({
            name = "onepassword-main-float",
            match = { tag = "pwd" },
            float = true,
            size = "1024 768",
        })
        hl.window_rule({
            name = "onepassword-dialog-tag",
            match = { class = "${class}", title = "^(.*)Password — 1Password$" },
            tag = "+pwd_dialog",
        })
        hl.window_rule({
            name = "onepassword-dialog-float",
            match = { tag = "pwd_dialog" },
            float = true,
            size = "1280 240",
            center = true,
            pin = true,
        })
      '';
    })
  ]);
}
