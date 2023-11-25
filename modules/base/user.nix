{ config, lib, pkgs, ... }: 

let

  inherit (lib) mkIf;
  inherit (builtins) hasAttr filter;

  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # Primary user defined in base
  user = config.users.user; 

  # public keys from the secrets dir
  keys = config.modules.secrets.keys;

  # agenix secrets combined secrets toggle
  secrets = config.age.secrets // { inherit (config.modules.secrets) enable; };

in {

  users.users = mkIf (user != "root") {
    "${user}" = {
      isNormalUser = true;
      shell = pkgs.zsh;
      home = "/home/${user}";
      description = user;
      passwordFile = mkIf (secrets.enable) secrets.password-hash.path;
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

}
# Correct $6$IGM3qj6OQ6e6ewhE$x1F9POsYCMONx80vydwySzN.WVF.5TfIZfi1b77ptrduoDM4v8SPGFva3ZIN7BYPGddLfzscN9O6TyiUOS8tc0
# Current $6$hxO0oX45eWp2myW/$vhRFbzKXh18hcylF0WyUzJ33v2i2I7HeAE2oFAT/fgWgK0ffA5qDtUoKTXwO4gjo1F.P7xZf4/zEfyYVxi9Wo/
# Prev.   $6$hxO0oX45eWp2myW/$vhRFbzKXh18hcylF0WyUzJ33v2i2I7HeAE2oFAT/fgWgK0ffA5qDtUoKTXwO4gjo1F.P7xZf4/zEfyYVxi9Wo/

