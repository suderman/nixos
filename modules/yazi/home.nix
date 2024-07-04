# programs.yazi.enable = true;
{ config, lib, pkgs, ... }: let 

  cfg = config.programs.yazi;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    programs.yazi = {
      package = pkgs.unstable.yazi;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

  };

}
