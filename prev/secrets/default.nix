# Compatible as both nixos and home-manager module
{ config, lib, this, ... }: 

let

  # Public keys
  # { users.all = []; systems.all = []; all = []; };
  keys = import ./keys;

  # Encrypted files
  # { my-password = ./files/password.age; ... }
  files = import ./files;

  hasUsers = length this.users > 0;
  inherit (lib) length mkOption types;

in {

  options.secrets = {

    # Automatically enable if there is at least 1 user (skip bootstrap)
    enable = mkOption { type = types.bool; default = hasUsers; };

    # Public keys
    keys = mkOption {
      type = types.anything;
      description = "Import secrets/keys/default.nix";
      default = keys;
    };

    # Encrypted files
    files = mkOption {
      type = types.anything;
      description = "Import secrets/files/default.nix";
      default = files;
    };

  };

}
