# programs.direnv.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.direnv;
  inherit (lib) mkDefault mkIf;
in {
  config = mkIf cfg.enable {
    programs.direnv = {
      nix-direnv.enable = mkDefault true;
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
  };
}
