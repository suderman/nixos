{ flake, config, pkgs, lib, ... }: let

  # inherit (lib) mkDefault mkIf mkOption types;
  inherit (lib) forEach pipe removePrefix removeSuffix mkOption types;
  inherit (flake.lib) ls mkAttrs;
  inherit (builtins) attrNames baseNameOf filter hasAttr mapAttrs;

  # List of nixosConfiguration usernames that also appear in flake.users
  userNames = map (userPath: pipe userPath [
    (path: toString path)
    (path: removeSuffix "/home-configuration.nix" path)
    (path: removeSuffix ".nix" path)
    (path: baseNameOf path)
  ]) (ls { path = config.path + /users; dirsWith = [ "home-configuration.nix" ]; });

  # List of user password names to be used in agenix secrets
  userPasswords = map (name: "user-${name}-password") (attrNames flake.users);
  userPasswordsHash = map (name: "user-${name}-password-hash") (attrNames flake.users);

  # Extract user name from agenix secrets password name
  getName = passwordName: removePrefix "user-" ( removeSuffix "-password" ( removeSuffix "-password-hash" passwordName ));

  # Return path to agenix hashed password file
  getPasswordFile = userName: config.age.secrets."user-${userName}-password-hash".path or null;

  # Filter list of groups to only those which exist
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

in {

  # Extra options for each user
  options.users.users = mkOption {
    type = with types; attrsOf (submodule {
      options.openssh.privateKey = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to age-encrypted user SSH private key";
        example = /etc/nixos/users/jon/id_ed25519.age;
      };
      options.openssh.publicKey = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to user SSH public key";
        example = /etc/nixos/users/jon/id_ed25519.pub;
      };
      options.path = mkOption { 
        description = "Path to user configuration directory";
        type = nullOr types.str;
        default = null;
        example = "/users/jon";
      };
    });
  };

  config = {

    # Disallow modifying users outside of this config
    users.mutableUsers = false;

    users.defaultUserShell = pkgs.zsh;

    age.secrets = (
      mkAttrs userPasswords (
        passwordName: let user = flake.users."${getName passwordName}" or {}; in { 
          rekeyFile = flake + "${user.path}/password.age"; 
        }
      )
    ) // (
      mkAttrs userPasswordsHash (
        passwordName: let user = flake.users."${getName passwordName}" or {}; in { 
          # rekeyFile = flake + "${user.path}/password-hash.age"; 
          generator.dependencies.password = config.age.secrets."${removeSuffix "-hash" passwordName}";
          generator.script = { pkgs, lib, decrypt, deps, ... }: ''
            ${pkgs.mkpasswd}/bin/mkpasswd -m sha-512 $(${decrypt} ${lib.escapeShellArg deps.password.file})
          '';
        }
      )
    );

    # Update users with details found in flake.users
    users.users = let

      userAccounts = mkAttrs userNames (name: let 
        user = flake.users."${name}" or {};
        groups = user.extraGroups or [];
      in user // {
        extraGroups = groups ++ ifTheyExist [ 
          "networkmanager" "docker" "media" "photos" 
        ];
        hashedPasswordFile = getPasswordFile name;
      });

      rootAccount = {
        root = flake.users.root or {} // { 
          hashedPasswordFile = getPasswordFile "root";
        }; 

      };

    in userAccounts // rootAccount;

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

  };

}
