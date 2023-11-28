{ config, lib, pkgs, ... }: 

let

  inherit (config.users) user;
  inherit (lib) mkIf;

  # public keys from the secrets dir
  keys = config.modules.secrets.keys;

  # agenix secrets combined secrets toggle
  secrets = config.age.secrets // { inherit (config.modules.secrets) enable; };

in {

  # Disallow modifying users outside of this config
  users.mutableUsers = false;

  # Configure root user
  users.users.root = {
    shell = pkgs.zsh;
    passwordFile = mkIf (secrets.enable) secrets.password-hash.path;
    password = mkIf (!secrets.enable) "root";
    openssh.authorizedKeys.keys = mkIf (user != "root") [ keys.users."${user}" ];
  };

  # Default shell
  programs.zsh.enable = true;

  # Allow root to work with git on the /etc/nixos directory
  system.activationScripts.root.text = ''
    printf "[safe]\ndirectory = /etc/nixos" > /root/.gitconfig
  '';

}
