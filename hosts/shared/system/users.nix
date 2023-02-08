{ config, lib, pkgs, user, ... }: 

with builtins;

let
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;
  inherit (lib) mkIf;

  # public keys from the secrets dir
  keys = config.secrets.keys;

  # agenix secrets combined with age files paths
  age = config.age // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };

in {

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------

  users = {

    mutableUsers = false;

    # root user
    users.root = {
      shell = pkgs.zsh;
      passwordFile = mkIf (age.enable) age.secrets.password.path;
      password = mkIf (!age.enable) "${user}";
      openssh.authorizedKeys.keys = [ keys.users."${user}" ];
    };

    # personal user
    users."${user}" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      home = "/home/${user}";
      description = user;
      passwordFile = mkIf (age.enable) age.secrets.password.path;
      password = mkIf (!age.enable) "${user}";
      extraGroups = [ 
        "wheel" 
      ] ++ ifTheyExist [
        "networkmanager" 
        "docker" 
        "input" 
        "keyd" 
        "uinput" 
      ]; 
      openssh.authorizedKeys.keys = [ keys.users."${user}" ];
    };

    # test user
    users."test" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      home = "/home/test";
      description = "test";
      passwordFile = mkIf (age.enable) age.secrets.password.path;
      password = mkIf (!age.enable) "test";
      extraGroups = [ 
        "wheel" 
      ] ++ ifTheyExist [
        "networkmanager" 
        "docker" 
        "input" 
        "keyd" 
        "uinput" 
      ]; 
      openssh.authorizedKeys.keys = [ keys.users."${user}" ];
    };

  };

  # agenix
  age.secrets = mkIf age.enable {
    password.file = age.files.password;
  };


}
