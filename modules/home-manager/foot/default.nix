# programs.foot.enable = true;
{ config, lib, pkgs, ... }:

let 
  cfg = config.programs.foot;

in {

  config = lib.mkIf cfg.enable {

    programs.foot.server.enable = true;

    programs.foot.settings = {

      main = {
        term = "xterm-256color";
        font = "monospace:size=8";
        dpi-aware = "yes";
      };

      mouse = {
        hide-when-typing = "yes";
      };

      key-bindings = {
        primary-paste = "Shift+Insert";
        # clipboard-paste = "Shift+Insert";
        clipboard-copy = "Control+Insert";
      };

    };

  };

}
