# https://github.com/daviaaze/nixfiles/blob/main/modules/services/beszel.nix
{ config, lib, pkgs, ... }: let

  cfg = config.services.beszel;
  inherit (builtins) toString;
  inherit (lib) mkIf mkOption ls types;

in {

  imports = ls ./.; # agent and hub

  options.services.beszel = {
    package = mkOption {
      type = types.package;
      default = pkgs.unstable.beszel; 
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/beszel";
    };
  };

  config = mkIf (cfg.enable || cfg.enableAgent) {

    environment.systemPackages = [ cfg.package ];

    users.users.beszel = {
      isSystemUser = true;
      description = "Beszel monitoring system";
      group = "beszel";
      extraGroups = [ "docker" ];
    };

    users.groups.beszel = {};

  };

}
