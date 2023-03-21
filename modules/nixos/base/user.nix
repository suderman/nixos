# base.enable = true;
{ config, lib, pkgs, user, ... }: with lib; with builtins; 

let
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # public keys from the secrets dir
  keys = config.secrets.keys;

  # agenix secrets combined secrets toggle
  secrets = config.age.secrets // { inherit (config.secrets) enable; };

in {

  config = mkIf config.base.enable {

    users.users = mkIf (user != "root") {
      "${user}" = {
        isNormalUser = true;
        shell = pkgs.zsh;
        home = "/home/${user}";
        description = user;
        passwordFile = mkIf (secrets.enable) secrets.password.path;
        password = mkIf (!secrets.enable) "${user}";
        extraGroups = [ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" ]; 
        openssh.authorizedKeys.keys = [ keys.users."${user}" ];
      };
    };

  };

}
