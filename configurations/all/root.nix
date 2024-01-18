{ config, lib, pkgs, ... }: 

let

  inherit (lib) mkIf;
  inherit (config) age;
  inherit (config.age) keys secrets;

in {

  # Disallow modifying users outside of this config
  users.mutableUsers = false;

  # Configure root user
  users.users.root = {
    shell = pkgs.zsh;
    hashedPasswordFile = mkIf (age.enable) secrets.password-hash.path;
    password = mkIf (!age.enable) "root";
    openssh.authorizedKeys.keys = keys.users.all;
  };

  # Default shell
  programs.zsh.enable = true;

  # Allow root to work with git on the /etc/nixos directory
  system.activationScripts.root.text = ''
    printf "[safe]\ndirectory = /etc/nixos" > /root/.gitconfig
  '';

}
