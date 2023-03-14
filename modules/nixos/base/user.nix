# base.enable = true;
{ config, lib, pkgs, user, ... }: with lib; with builtins; 

let
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # public keys from the secrets dir
  keys = config.secrets.keys;

  # agenix secrets combined with age files paths
  age = config.age // { 
    files = config.secrets.files; 
    enable = config.secrets.enable; 
  };

in {

  config = mkIf config.base.enable {

    # agenix
    age.secrets = mkIf age.enable {
      password.file = age.files.password;
    };

    users.users = mkIf (user != "root") {
      "${user}" = {
        isNormalUser = true;
        shell = pkgs.zsh;
        home = "/home/${user}";
        description = user;
        passwordFile = mkIf (age.enable) age.secrets.password.path;
        password = mkIf (!age.enable) "${user}";
        extraGroups = [ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" ]; 
        openssh.authorizedKeys.keys = [ keys.users."${user}" ];
      };
    };

  };

}
