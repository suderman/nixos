# config.programs.rofi.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.programs.rofi;
  inherit (lib) concatStringsSep getExe mkDefault mkOption mkIf types;
in {
  imports = flake.lib.ls ./.;

  options.programs.rofi = {
    extraSinks = mkOption {
      type = with types; listOf str;
      default = [];
    };
    hiddenSinks = mkOption {
      type = with types; listOf str;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    programs.rofi = {
      package = pkgs.unstable.rofi;
      plugins = with pkgs; [rofi-calc rofi-emoji-wayland rofimoji rofi-blezz];
      cycle = false;
      terminal = getExe pkgs.kitty;
      font = mkDefault "JetBrainsMono 14";
      extraConfig = {
        icon-theme = "Papirus";
        show-icons = true;
        modes = [
          "combi"
          "calc"
          "emoji"
          "blezz"
          "sinks:rofi-sinks"
        ];
        combi-modes = [
          "hyprwindow:rofi-hyprwindow"
          "drun"
          "ssh"
        ];

        separator-style = "dash";
        color-enabled = true;
        display-hyprwindow = "";
        display-window = "";
        display-drun = "";
        display-run = "run";

        kb-accept-entry = ["space" "Return"];
        kb-mode-next = ["Alt_L" "Shift+Right" "Control+Tab"];
        kb-mode-previous = ["Shift+Alt_L" "Shift+Left" "Control+ISO_Left_Tab"];
        me-select-entry = "MousePrimary";
        me-accept-entry = "!MousePrimary";

        # rofi-calc
        calc-command = "echo -n '{result}' | wl-copy";
        kb-accept-custom = ["backslash" "Control+Return"];
      };
    };

    wayland.windowManager.hyprland.settings = let
      combi = "rofi-toggle -show combi";
      blezz = "rofi-toggle -show blezz -auto-select -matching normal -theme-str 'window {width: 50%;}'";
      sinks = "rofi-toggle -show sinks -cycle -theme-str 'window {width: 50%;}'";
    in {
      bindr = [
        "super, Super_L, exec, ${combi}" # Left Super is app launcher/switcher
        "super, Super_R, exec, ${blezz}" # Right Super is blezz
      ];

      bind = [
        ", XF86AudioMedia, exec, ${sinks}"
        "super, space, exec, ${combi}"
        "super+alt, space, exec, ${blezz}"
      ];
      bindsn = [
        "super_l, a&s, exec, ${sinks}"
        "super_r, a&s, exec, ${sinks}"
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

    xdg.configFile = {
      "rofi/extra.sinks".text = concatStringsSep "\n" cfg.extraSinks;
      "rofi/hidden.sinks".text = concatStringsSep "\n" cfg.hiddenSinks;
    };

    # extra packages
    home.packages = with pkgs; [
      papirus-icon-theme
    ];
  };
}
