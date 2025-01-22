{ config, ... }: {

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global.load_dotenv = true;
      global.strict_env = true;
      whitelist.prefix = [ "${config.home.homeDirectory}/Work" ];
    };
  };

}
