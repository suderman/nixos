# services.open-webui.enable = true;
{ config, lib, pkgs, ... }: let 

  cfg = config.services.open-webui;
  inherit (builtins) toString;
  inherit (lib) mkIf mkOption types;

in {

  options.services.open-webui = {
    name = mkOption {
      type = types.str; 
      default = "open-webui";
    };
  };

  config = mkIf cfg.enable {
    # services.traefik.proxy."${cfg.name}" = "http://127.0.0.1:${toString cfg.port}";
    # services.ollama.enable = true;
  };

}
