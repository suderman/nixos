{ config, lib, ... }: {

  programs.direnv = {
    enable = lib.mkDefault true;
    nix-direnv.enable = lib.mkDefault true;
    config = {
      global.load_dotenv = true;
      global.strict_env = true;
      whitelist.prefix = [ 
        "${config.home.homeDirectory}/Code" 
        "${config.home.homeDirectory}/Work" 
      ];
    };
  };

}
