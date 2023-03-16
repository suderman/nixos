# programs.wezterm.enable = true;
{ config, lib, ... }: {

  config = lib.mkIf config.programs.wezterm.enable {
    programs.wezterm.extraConfig = builtins.readFile ./wezterm.lua;
  };

}
