# programs.direnv.enable = true;
{ config, lib, pkgs, ... }:

let 
  cfg = config.programs.direnv;

in {

  config = lib.mkIf cfg.enable {

    programs.direnv.nix-direnv.enable = true;

    xdg.configFile."direnv/direnv.toml".text = ''
      [global]
      load_dotenv = true
      strict_env = true

      [whitelist]
      prefix = [ "${config.home.homeDirectory}/Code" ]
    '';

  };

}
