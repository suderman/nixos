# programs.kitty.enable = true;
{ config, lib, pkgs, ... }: 

let
  cfg = config.programs.kitty;

in {

  config = lib.mkIf cfg.enable {

    programs.kitty = {

      theme = "Space Gray Eighties";

      settings = {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
      };

      environment = {
        "LS_COLORS" = "";
      };

      keybindings = {
        "ctrl+c" = "copy_or_interrupt";
        "ctrl+f>2" = "set_font_size 20";
      };

      extraConfig = ''
      '';

    };

  };

}
