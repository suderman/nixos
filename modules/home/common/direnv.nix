# programs.direnv.enable = true;
{
  config,
  lib,
  ...
}: {
  programs.direnv = {
    nix-direnv.enable = lib.mkDefault true;
    config = {
      global.load_dotenv = true;
      global.strict_env = true;
      whitelist.prefix = [
        "/etc/nixos"
        "${config.home.homeDirectory}/Code"
        "${config.home.homeDirectory}/Work"
      ];
    };
  };
}
