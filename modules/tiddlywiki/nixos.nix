# services.tiddlywiki.enable = true;
{ config, lib, pkgs, this, ... }: let

  cfg = config.services.tiddlywiki;
  inherit (lib) mkIf mkOption mkBefore types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.services.tiddlywiki = {
    name = mkOption {
      type = types.str;
      default = "tiddlywiki";
    };
    port = mkOption {
      default = 3456;
      type = types.port;
    };
  };

  config = mkIf cfg.enable {

    # Add admins to the tiddlywiki group
    users.users = extraGroups this.admins [ "tiddlywiki" ];

    services.tiddlywiki = {
      listenOptions = {
        port = cfg.port;
        # credentials = "../credentials.csv";
        # readers="(authenticated)";
      };
    };

    services.traefik = { 
      enable = true;
      proxy.${cfg.name} = "http://127.0.0.1:${toString cfg.port}";
    };

  };

}
