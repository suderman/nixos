{ config, lib, pkgs, this, ... }: 

let

  inherit (lib) mkIf mkOption types;
  inherit (builtins) hasAttr filter;
  inherit (this.lib) mkAttrs;

  # Filter list of groups to only those which exist
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # Return passed list if user is admin, else return empty list
  ifAdmin = user: list: if builtins.elem user this.admins then list else [];

  # public keys from the secrets dir
  keys = config.modules.secrets.keys.users.all;

  # agenix secrets combined secrets toggle
  secrets = config.age.secrets // { inherit (config.modules.secrets) enable; };

in {

  # Add all users found in configurations/*/home/*
  users.users = mkAttrs this.users (user: { 
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/${user}";
    description = user;
    hashedPasswordFile = mkIf (secrets.enable) secrets.password-hash.path;
    password = mkIf (!secrets.enable) "${user}";
    extraGroups = ifAdmin user ([ "wheel" ] ++ ifTheyExist [ "networkmanager" "docker" "media" "photos" ]);
    openssh.authorizedKeys.keys = keys;
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

}
