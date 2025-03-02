{ config, lib, inputs, ... }: let 

  cfg = config.secrets;
  inherit (lib) mkIf mkAttrs mkOption types;

in {

  # Import agenix module
  imports = [ inputs.agenix.homeManagerModules.default ];

  # Extend age options
  options.age = {

    # Add age.enable option matching secrets.enable
    enable = mkOption { type = types.bool; default = cfg.enable; };

    # Add age.keys option matching secrets.keys
    keys = mkOption { type = types.anything; default = cfg.keys; };

  };

  config = mkIf cfg.enable {

    # The NixOS module fetches all secrets, which is OK since these are owned by root
    # However, if the home-manager module did this, all secrets would be also be owned by a normal user
    # Therefore, we comment this out
    #
    # age.secrets = mkAttrs cfg.files (key: {
    #   file = cfg.files."${key}"; 
    #   mode = "440";
    # });

    # Instead, we opt into selective secrets to decrypt by the user. Example:
    # 
    # Add decrypted secrect to /run/user/1000/agenix/*
    # age.secrets.password.file = config.secrets.files.password;
    #
    # Assign session variable with value of decrypted secret
    # home.sessionVariables = {
    #   SECRET_PASSWORD = "$(cat ${config.age.secrets.password.path})";
    # };

    # Try these keys to decrypt secrets
    age.identityPaths = with config.home; [ 
      "${homeDirectory}/.ssh/id_ed25519" 
      "${homeDirectory}/.ssh/id_rsa" 
    ];

  };

}
