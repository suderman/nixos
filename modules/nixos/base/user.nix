{ config, lib, pkgs, user, ... }: 

let

  cfg = config.modules.base;
  inherit (lib) mkIf;
  inherit (builtins) hasAttr filter;

  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # public keys from the secrets dir
  keys = config.modules.secrets.keys;

  # agenix secrets combined secrets toggle
  secrets = config.age.secrets // { inherit (config.modules.secrets) enable; };

in {

  config = mkIf cfg.enable {

    users.users = mkIf (user != "root") {
      "${user}" = {
        isNormalUser = true;
        shell = pkgs.zsh;
        home = "/home/${user}";
        description = user;
        passwordFile = mkIf (secrets.enable) secrets.password-encrypted.path;
        password = mkIf (!secrets.enable) "${user}";
        extraGroups = [ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" ]; 
        openssh.authorizedKeys.keys = [ keys.users."${user}" ];
      };
    };

  };

}
