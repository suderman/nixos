{ config, lib, pkgs, user, ... }:

let
  cfg = config.services.mysql;

in {

  # services.mysql.enable = true;
  services.mysql.package = pkgs.mysql80;
  services.mysql.ensureUsers = [{
    name = user;
    ensurePermissions = {
      "*.*" = "ALL PRIVILEGES";
    };
  }];

}
