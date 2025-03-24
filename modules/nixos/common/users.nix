{ flake, config, pkgs, lib, ... }: let

  # inherit (lib) mkDefault mkIf mkOption types;
  inherit (lib) forEach pipe removeSuffix;
  inherit (flake.lib) ls mkAttrs;
  inherit (builtins) attrNames baseNameOf filter hasAttr mapAttrs;

  # List of nixosConfiguration users that also appear in flake.users
  # users = filter (user: user != "root" && hasAttr user flake.users) (attrNames config.users.users);

  # List of nixosConfiguration usernames that also appear in flake.users
  userNames = map (userPath: pipe userPath [
    (path: toString path)
    (path: removeSuffix "/home-configuration.nix" path)
    (path: removeSuffix ".nix" path)
    (path: baseNameOf path)
  ]) (ls { path = config.path + /users; dirsWith = [ "home-configuration.nix" ]; });

  # Lookup user attributes in flake.users and set fallbacks
  users = mkAttrs userNames (userName: rec {
    user = flake.users."${userName}" or {}; 
    name = user.name or userName;
    uid = user.uid or null;
    description = user.description or "";
    shell = user.shell or "zsh";
    isSystemUser = user.isSystemUser or false;
    sudo = user.sudo or false;
    home = user.home or "/home/${name}";
  }); 

  # Same for root user
  root = rec {
    user = flake.users."root" or {}; 
    name = user.name or "root";
    uid = user.uid or 0;
    description = user.description or "";
    shell = user.shell or "zsh";
  }; 

  # Filter list of groups to only those which exist
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # Return group list if user can sudo, else return empty list
  sudoGroup = user: let sudo = user.sudo or false; in if sudo then [ "wheel" ] else [];

in {

  # Disallow modifying users outside of this config
  users.mutableUsers = false;

  # Update users with details found in flake.users
  users.users = {

    # Update root with details found in flake.users
    root = rec {
      inherit (root) uid name;
      shell = pkgs."${root.shell}" or pkgs.shadow;
      password = name;
      # hashedPasswordFile = mkIf (age.enable) secrets.password-hash.path;
      # openssh.authorizedKeys.keys = keys.users.all;
    };

  } // (mapAttrs (_: user: rec { 
    inherit (user) uid name description isSystemUser home;
    isNormalUser = ! isSystemUser;
    password = name;
    extraGroups = sudoGroup user ++ ifTheyExist [ "networkmanager" "docker" "media" "photos" ];
    shell = pkgs."${user.shell}" or pkgs.shadow;
    # openssh.authorizedKeys.keys = keys.users.all;
    linger = true; # start/stop systemd user units at boot/shutdown instead of user login/logout
  }) users);

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

  # Default shell
  programs.zsh.enable = true;

  # Allow root to work with git on the /etc/nixos directory
  system.activationScripts.root.text = ''
    printf "[safe]\ndirectory = /etc/nixos" > /root/.gitconfig
  '';

}
