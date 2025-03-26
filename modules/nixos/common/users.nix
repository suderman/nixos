{ flake, config, pkgs, lib, ... }: let

  # inherit (lib) mkDefault mkIf mkOption types;
  inherit (lib) forEach genAttrs pipe removePrefix removeSuffix mkOption types;
  inherit (flake.lib) ls mkAttrs;
  inherit (builtins) attrNames baseNameOf filter hasAttr mapAttrs toString;

  # Include all user password.age files as an agenix secret as user-password
  userPasswords = genAttrs 
    (map (userName: "${userName}-password") (attrNames flake.users))
    (secretName: let userName = removeSuffix "-password" secretName; in {
      rekeyFile = flake + "${flake.users."${userName}".path}/password.age"; 
    });

  # Generate hashed versions of the above secret as user-password-hash
  userHashedPasswords = genAttrs 
    (map (userName: "${userName}-password-hash") (attrNames flake.users))
    (secretName: let userName = removeSuffix "-password-hash" secretName; in {
      generator.dependencies = {
        hex = config.age.secrets.hex; # hex as custom salt for mkpasswd
        password = config.age.secrets."${userName}-password";
      };
      generator.script = { pkgs, lib, decrypt, deps, ... }: toString [
        "${pkgs.mkpasswd}/bin/mkpasswd -m sha-512 -S" 
        "$(${decrypt} ${lib.escapeShellArg deps.hex.file} | cut -c 1-16)" 
        "$(${decrypt} ${lib.escapeShellArg deps.password.file})"
      ];
    });

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

    # Add user passwords to agenix
    age.secrets = userPasswords // userHashedPasswords;

    # Disallow modifying users outside of this config
    users.mutableUsers = false;

    users.defaultUserShell = pkgs.zsh;

    # Update users with details found in flake.users
    users.users = let

      # List of nixosConfiguration usernames that also appear in flake.users
      userNames = map (userPath: pipe userPath [
        (path: toString path)
        (path: removeSuffix "/home-configuration.nix" path)
        (path: removeSuffix ".nix" path)
        (path: baseNameOf path)
      ]) (ls { path = config.path + /users; dirsWith = [ "home-configuration.nix" ]; });

      # Each user account found in flake.users
      userAccounts = mkAttrs userNames (name: let 
        user = flake.users."${name}" or {};
        groups = user.extraGroups or [];
      in user // {
        hashedPasswordFile = config.age.secrets."${name}-password-hash".path;
        extraGroups = groups ++ ifTheyExist [ 
          "networkmanager" "docker" "media" "photos" 
        ];
      });

      # Special case for flake.users.root
      rootAccount = { root = flake.users.root or {} // { 
        hashedPasswordFile = config.age.secrets."root-password-hash".path;
      }; };

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
