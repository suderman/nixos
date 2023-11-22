# Compatible as both nixos and home-manager module
{ config, lib, ... }: 

let

  cfg = config.modules.secrets;
  inherit (lib) mkIf;

in {

  modules.secrets = mkIf cfg.enable {

    # Public keys
    keys = import ./keys;

    # Encrypted files
    files = import ./files;

  };

}
