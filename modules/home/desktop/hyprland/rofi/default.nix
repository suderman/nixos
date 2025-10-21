{
  lib,
  pkgs,
  flake,
  ...
}: {
  imports = flake.lib.ls ./.;

  programs.rofi = {
    enable = true;
    package = pkgs.unstable.rofi;
    cycle = false;
    terminal = lib.getExe pkgs.kitty;
    font = lib.mkDefault "JetBrainsMono 14";
    extraConfig = {
      icon-theme = "Papirus";
      show-icons = true;
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
}
