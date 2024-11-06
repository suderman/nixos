{ config, lib, pkgs, this, ... }: 

let

  inherit (lib) mkIf mkOption types;
  inherit (builtins) hasAttr filter;
  inherit (this.lib) mkAttrs attrNameByValue;
  inherit (config) age;
  inherit (config.age) secrets keys;

  # Filter list of groups to only those which exist
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # Return passed list if user is admin, else return empty list
  ifAdmin = user: list: if builtins.elem user this.admins then list else [];

in {

  # User 1000's name
  options.user = mkOption { 
    type = types.str; 
    default = attrNameByValue 1000 config.ids.uids;
  };

  # Configuration for all normal users 
  config = {

    # Add all users found in configurations/*/users/*
    users.users = mkAttrs this.users (user: { 
      uid = with config.ids; if hasAttr user uids then uids."${user}" else null;
      isNormalUser = true;
      shell = pkgs.zsh;
      home = "/home/${user}";
      description = user;
      hashedPasswordFile = mkIf (age.enable) secrets.password-hash.path;
      password = mkIf (!age.enable) "${user}";
      extraGroups = ifAdmin user ([ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" "media" "photos" ]);
      openssh.authorizedKeys.keys = keys.users.all;
    }); 

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
