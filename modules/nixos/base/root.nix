# base.enable = true;
{ config, lib, pkgs, user, ... }: with lib; with builtins; 

let

  # public keys from the secrets dir
  keys = config.secrets.keys;

  # agenix secrets combined secrets toggle
  age = config.age // { inherit (config.secrets) enable; };

in {

  config = mkIf config.base.enable {

    # Disallow modifying users outside of this config
    users.mutableUsers = false;

    # Configure root user
    users.users.root = {
      shell = pkgs.zsh;
      passwordFile = mkIf (age.enable) age.secrets.password.path;
      password = mkIf (!age.enable) "root";
      openssh.authorizedKeys.keys = mkIf (user != "root") [ keys.users."${user}" ];
    };

    # Allow root to work with git on the /etc/nixos directory
    system.activationScripts.root.text = ''
      printf "[safe]\ndirectory = /etc/nixos" > /root/.gitconfig
    '';

  };

}
