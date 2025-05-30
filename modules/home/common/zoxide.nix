# programs.zoxide.enable = true;
{ config, lib, pkgs, ... }: let

  cfg = config.programs.zoxide;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    programs.zoxide = {
      enableBashIntegration = true;
      enableZshIntegration = true;
      package = pkgs.zoxide;
    };

    persist.directories = [ ".local/share/zoxide" ];

  };

}
