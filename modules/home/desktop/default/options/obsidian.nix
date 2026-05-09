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
    # Make default application for markdown
    xdg.mimeApps.defaultApplications = {
      "text/markdown" = ["obsidian.desktop"];
      "text/x-markdown" = ["obsidian.desktop"];
      "x-scheme-handler/obsidian" = ["obsidian.desktop"];
    };
    wayland.windowManager.hyprland.lua.features.obsidian = ''
      hl.window_rule({
          name = "obsidian-notes-tag",
          match = { class = "${class}" },
          tag = "+notes",
      })
    '';
  };
}
