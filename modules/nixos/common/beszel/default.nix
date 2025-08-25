# https://github.com/daviaaze/nixfiles/blob/main/modules/services/beszel.nix
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  cfg = config.services.beszel;
  inherit (lib) mkIf mkOption types;
in {
  imports = flake.lib.ls ./.; # agent and hub

  options.services.beszel = {
    package = mkOption {
      type = types.package;
      default = pkgs.beszel;
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/beszel";
    };
  };

  config = mkIf (cfg.enable || cfg.enableAgent) {
    environment.systemPackages = [cfg.package];

    users.users.beszel = {
      isSystemUser = true;
      description = "Beszel monitoring system";
      group = "beszel";
      extraGroups = ["docker"];
    };

    users.groups.beszel = {};

    tmpfiles.directories = [
      {
        target = "${cfg.dataDir}/beszel_data";
        user = "beszel";
      }
    ];

    impermanence.persist.directories = [cfg.dataDir];
  };
}
