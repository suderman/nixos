# programs.direnv.enable = true;
{ config, lib, pkgs, ... }: let 

  cfg = config.programs.direnv;
  inherit (config.home) homeDirectory;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    programs.direnv = {
      nix-direnv.enable = true;
      config = {
        global.load_dotenv = true;
        global.strict_env = true;
        whitelist.prefix = [ "${homeDirectory}/Work" ];
      };
    };

    # xdg.configFile."direnv/direnv.toml".text = ''
    #   [global]
    #   load_dotenv = true
    #   strict_env = true
    #
    #   [whitelist]
    #   prefix = [ "${config.home.homeDirectory}/Code" ]
    # '';

  };

}
