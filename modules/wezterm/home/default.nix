# programs.wezterm.enable = true;
{ config, lib, pkgs, ... }: {

  config = lib.mkIf config.programs.wezterm.enable {
    programs.wezterm = {
      extraConfig = builtins.readFile ./wezterm.lua;
      package = pkgs.unstable.wezterm;
    };
  };

}
