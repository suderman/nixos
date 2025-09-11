{
  config,
  lib,
  ...
}: let
  cfg = config.programs.localsend;
in {
  config = lib.mkIf cfg.enable {
    programs.localsend.openFirewall = true;
  };
}
