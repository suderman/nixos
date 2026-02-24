# programs.obsidian.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.obsidian;
  class = "obsidian";
in {
  config = lib.mkIf cfg.enable {
    programs.obsidian = {
      package = pkgs.unstable.obsidian;
    };

    # Persist application state and let Obsidian manage it
    persist.scratch.directories = [".config/obsidian"];
    xdg.configFile = {
      "obsidian".enable = false;
      "obsidian/obsidian.json".enable = false;
    };

    # Tag windows for hyprland
    wayland.windowManager.hyprland.settings = {
      windowrule = ["tag +notes, match:class (${class})"];
    };

    # Make default application for markdown
    xdg.mimeApps.defaultApplications = {
      "text/markdown" = ["obsidian.desktop"];
      "text/x-markdown" = ["obsidian.desktop"];
      "x-scheme-handler/obsidian" = ["obsidian.desktop"];
    };
  };
}
