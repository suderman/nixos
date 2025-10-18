# config.programs.rofi.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.rofi;
  inherit (lib) getExe mkDefault mkIf;
in {
  imports = flake.lib.ls ./.;

  config = mkIf cfg.enable {
    programs.rofi = {
      package = pkgs.unstable.rofi;
      plugins = [pkgs.unstable.rofi-emoji];
      cycle = false;
      terminal = getExe pkgs.kitty;
      font = mkDefault "JetBrainsMono 14";
      extraConfig = {
        icon-theme = "Papirus";
        show-icons = true;
        modes = [
          "combi"
          "emoji"
        ];
        combi-modes = [
          "hyprland:rofi-hyprland"
          "drun"
          "ssh"
        ];

        separator-style = "dash";
        color-enabled = true;
        display-hyprland = "";
        display-window = "";
        display-drun = "";
        display-run = "run";

        kb-accept-entry = ["space" "Return"];
        kb-mode-next = ["Alt_L" "Shift+Right" "Control+Tab"];
        kb-mode-previous = ["Shift+Alt_L" "Shift+Left" "Control+ISO_Left_Tab"];
        me-select-entry = "MousePrimary";
        me-accept-entry = "!MousePrimary";
        kb-accept-custom = ["backslash" "Control+Return"];
      };
    };

    wayland.windowManager.hyprland.settings = let
      combi = "rofi-toggle -show combi";
    in {
      bindr = [
        "super, Super_L, exec, ${combi}" # Left Super is app launcher/switcher
      ];
      bind = [
        "super, space, exec, ${combi}"
      ];
    };

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

    # extra packages
    home.packages = with pkgs; [
      papirus-icon-theme
    ];
  };
}
