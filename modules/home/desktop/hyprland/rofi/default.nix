{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.rofi;
in {
  imports = flake.lib.ls ./.;

  options.programs.rofi = {
    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    rasiConfig = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    rasiConfigPath = lib.mkOption {
      type = lib.types.str;
      default = "${builtins.dirOf cfg.configPath}/extra.rasi";
    };
    mode = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        slot1 = "combi";
      };
    };
  };

  config = {
    programs.rofi = {
      enable = true;
      package = pkgs.unstable.rofi;
      cycle = false;
      terminal = lib.getExe pkgs.kitty;
      modes = lib.mapAttrsToList (_: mode: mode) cfg.mode; # ordered modes
      extraConfig = {
        show-icons = true;
        separator-style = "dash";
        sidebar-mode = true;
        scroll-method = 0;
        color-enabled = true;
        kb-accept-entry = ["space" "Return"];
        kb-mode-next = ["Alt_L" "Shift+Right" "Control+Tab"];
        kb-mode-previous = ["Shift+Alt_L" "Shift+Left" "Control+ISO_Left_Tab"];
        me-select-entry = "MousePrimary";
        me-accept-entry = "!MousePrimary";
        kb-accept-custom = ["backslash" "Control+Return"];
      };
    };

    # Import extra rasi config at end of file
    home.file."${cfg.configPath}".text = lib.mkAfter ''
      @import "extra"
    '';

    # Create extra config file next to default config
    home.file."${cfg.rasiConfigPath}".text = ''
      configuration {
        ${builtins.concatStringsSep "\n" cfg.rasiConfig}
      }
    '';

    # Use a real file for the rofi config to ease real-time tinkering
    home.localStorePath = [
      ".config/rofi/config.rasi"
      ".config/rofi/extra.rasi"
    ];

    # Special keyd keymaps for rofi
    services.keyd.layers = {
      rofi = {
        "super.tab" = "down";
        "super.grave" = "up";
        "super.j" = "down";
        "super.k" = "up";
        "super.h" = "left";
        "super.l" = "right";
        "super.enter" = "enter";
        "super.escape" = "escape";
        "super.q" = "escape";
        "super.x" = "escape";
      };
    };

    # Pretty animations in hyprland
    wayland.windowManager.hyprland.settings.animations.layerrule = [
      # "animation fade, rofi"
      # "dimaround, rofi"
      "animation fade, dim_around on, match:namespace rofi"
    ];
  };
}
