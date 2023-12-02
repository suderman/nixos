{ config, lib, pkgs, this, ... }: 

let

  inherit (lib) mkIf mkOption types;
  inherit (builtins) hasAttr filter;

  # Filter list of groups to only those which exist
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # Primary user defined in this
  user = this.user; 

  # public keys from the secrets dir
  keys = config.modules.secrets.keys;

  # agenix secrets combined secrets toggle
  secrets = config.age.secrets // { inherit (config.modules.secrets) enable; };

in {

  # Create new users.user option to store user name defined in this
  options.users.user = mkOption { type = types.str; default = user; };

  config = {

    users.users = mkIf (user != "root") {
      "${user}" = {
        isNormalUser = true;
        shell = pkgs.zsh;
        home = "/home/${user}";
        description = user;
        hashedPasswordFile = mkIf (secrets.enable) secrets.password-hash.path;
        password = mkIf (!secrets.enable) "${user}";
        extraGroups = [ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" "media" "photos" ]; 
        openssh.authorizedKeys.keys = [ keys.users."${user}" ];
      };
    };

    # GIDs 900-909 are custom shared groups in my flake                                                                                                                                   
    # UID/GIDs 910-999 are custom system users/groups in my flake                                                                                                                         

    # Create secrets group
    ids.gids.secrets = 900;
    users.groups.secrets.gid = config.ids.gids.secrets;
                                                                                                                                                                                          
    # Create media group                                                                                                                                                                  
    ids.gids.media = 901;                                                                                                                                                                 
    users.groups.media.gid = config.ids.gids.media;                                                                                                                                       
                                                                                                                                                                                          
    # Create photos group                                                                                                                                                                 
    ids.gids.photos = 902;                                                                                                                                                                
    users.groups.photos.gid = config.ids.gids.photos;

  };

}
