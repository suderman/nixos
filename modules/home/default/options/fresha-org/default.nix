{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.fresha-org;
  fresha-org = perSystem.self.mkScript {
    name = "fresha-org";
    text = ''
      exec ${lib.getExe pkgs.nodejs_24} ${./fresha-org.js} "$@"
    '';
  };
in {
  options.programs.fresha-org.enable = lib.mkEnableOption "Fresha staff shifts as Org events";

  config = lib.mkIf cfg.enable {
    home.packages = [fresha-org];
  };
}
