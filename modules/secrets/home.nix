# modules.secrets.enable = true;
{ config, lib, inputs, ... }: 

let 

  cfg = config.modules.secrets;
  inherit (lib) mkIf mkOption types;
  inherit (lib.options) mkEnableOption;

in {

  # Import homeage module
  imports = [ inputs.homeage.homeManagerModules.homeage ];

  options.modules.secrets = {

    # Must opt into secrets
    enable = mkEnableOption "secrets"; 

    # Public keys
    keys = mkOption {
      type = types.attrs;
      description = "Import secrets/keys/default.nix";
      default = { users.all = []; systems.all = []; all = []; };
    };

    # Encrypted files
    files = mkOption {
      type = types.attrs;
      description = "Import secrets/files/default.nix";
      default = {};
    };

  };

  config = mkIf cfg.enable {

    # Configure homeage (agenix for home-manager)
    homeage.identityPaths = [ "~/.ssh/id_rsa" ];

  };

}
