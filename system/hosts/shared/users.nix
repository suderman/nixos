{ config, lib, pkgs, user, ... }: 

with builtins;

let
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;
  inherit (config) secrets;
  inherit (lib) mkIf;

in {

  # ---------------------------------------------------------------------------
  # User Configuration
  # ---------------------------------------------------------------------------

  users = {

    mutableUsers = false;

    # root user
    users.root = {
      shell = pkgs.zsh;
      passwordFile = mkIf (secrets.enable) config.age.secrets.password.path;
      password = mkIf (!secrets.enable) "${user}";
      openssh.authorizedKeys.keys = [ config.keys."${user}" ];
    };

    # personal user
    users."${user}" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      home = "/home/${user}";
      description = user;
      passwordFile = mkIf (secrets.enable) config.age.secrets.password.path;
      password = mkIf (!secrets.enable) "${user}";
      extraGroups = [ 
        "wheel" 
      ] ++ ifTheyExist [
        "networkmanager" 
        "docker" 
        "input" 
        "keyd" 
        "uinput" 
      ]; 
      openssh.authorizedKeys.keys = [ config.keys."${user}" ];
    };

    # test user
    users."test" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      home = "/home/test";
      description = "test";
      passwordFile = mkIf (secrets.enable) config.age.secrets.password.path;
      password = mkIf (!secrets.enable) "test";
      extraGroups = [ 
        "wheel" 
      ] ++ ifTheyExist [
        "networkmanager" 
        "docker" 
        "input" 
        "keyd" 
        "uinput" 
      ]; 
      openssh.authorizedKeys.keys = [ config.keys."${user}" ];
    };

  };

  # agenix
  age.secrets = with secrets; mkIf secrets.enable {
    password.file = password;
  };


}
