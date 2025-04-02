{ flake, config, pkgs, lib, perSystem, ... }: let

  inherit (lib) concatMapStrings genAttrs mkAfter mkOption pipe removeSuffix types;
  inherit (flake.lib) ls mkAttrs;
  inherit (builtins) attrNames baseNameOf filter hasAttr toString;
  inherit (perSystem.self) mkScript;

in {

  # List of nixosConfiguration usernames that also appear in flake.users
  options.users.names = mkOption {
    type = with types; listOf str;
    default = map (userPath: pipe userPath [
      (path: removeSuffix "/home-configuration.nix" path)
      (path: removeSuffix ".nix" path)
      (path: baseNameOf path)
    ]) (ls { 
      path = flake + /hosts/${config.networking.hostName}/users; 
      dirsWith = [ "home-configuration.nix" ]; 
      asPath = false;
    });
  };

  # Extra options for each user
  options.users.users = mkOption {
    type = with types; attrsOf (submodule {
      options.openssh.privateKey = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to user SSH private key file";
        example = /run/agenix/jon-key;
      };
      options.openssh.publicKey = mkOption {
        type = nullOr str;
        default = null;
        description = "User SSH public key";
        example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPviN4LtuWOvvSMomJeXbWn7AIZGDQoagNmkg4Y2UePa jon@bip85-hex32-index1";
      };
    });
  };

  config = {

    # Update users with details found in flake.users
    users.users = let

      # Filter list of groups to only those which exist
      ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

      # Get a user by name from the flake
      flakeUser = name: rec {
        inherit name;
        user = flake.users."${name}" or {};
        openssh = user.openssh or {};
        privateKey = config.age.secrets."${name}-key".path;
        hashedPasswordFile = "/run/user/${name}"; # generated in activation script
        extraGroups = user.extraGroups ++ ifTheyExist [ 
          "networkmanager" "docker" "media" "photos" 
        ];
      };

      # Each user account found in flake.users
      userAccounts = mkAttrs config.users.names (name: let u = flakeUser name; in u.user // {
        extraGroups = u.extraGroups;
        openssh = u.openssh // { inherit (u) privateKey; };
        hashedPasswordFile = if config.users.users."${u.name}".password == null 
          then u.hashedPasswordFile else null;
      });

      # Special case for flake.users.root
      rootAccount = let u = flakeUser "root"; in { "${u.name}" = u.user // { 
        hashedPasswordFile = if config.users.users."${u.name}".password == null 
          then u.hashedPasswordFile else null;
        openssh = u.openssh // { inherit (u) privateKey; };
      }; };

    in userAccounts // rootAccount;

    # Disallow modifying users outside of this config
    users.mutableUsers = false;

    # Everybody can use zsh
    users.defaultUserShell = pkgs.zsh;
    programs.zsh.enable = true;

    # Allow root to work with git on the /etc/nixos directory
    # system.activationScripts.root.text = ''
    #   printf "[safe]\ndirectory = /etc/nixos" > /root/.gitconfig
    # '';

    # Hash user password & write SSH keys to each ~/.ssh directory
    system.activationScripts = let

      inherit (lib) mkAfter;
      inherit (perSystem.self) mkScript;
      hex = config.age.secrets.hex.path;

      everyone = config.users.names ++ [ "root" ];
      usermeta = name: {

        # Get user from nixos configuration
        user = config.users.users.${name};

        # Public ssh user key derived from 32-byte hex
        publicKey = flake + /users/${name}/id_ed25519.pub;

        # Password encrypted with age identity
        password = config.age.secrets."${name}-password".path;

      };

    in {

      # Hash user password and save to /run/user
      agenixInstall.text = let
        perUser = userName: let 
          inherit (usermeta userName) user password;

        # Hash user password and store as file in /run/user
        in ''
          if [[ -f ${hex} ]]; then 
            mkdir -p /run/user
            mkpasswd -m sha-512 -S $(cat ${hex} | cut -c 1-16) $(cat ${password}) \
            > /run/user/${userName}
            chmod 600 /run/user/${userName}
          fi
        '';

        text = concatMapStrings perUser everyone;
        path = [ pkgs.mkpasswd ];

      in mkAfter "${mkScript { inherit text path ; }}";

      # Write SSH keys to each ~/.ssh directory
      users.text = let
        perUser = userName: let 
          inherit (usermeta userName) user publicKey password;

        # Ensure ~/.ssh exists 
        in ''
          mkdir -p ${user.home}/.ssh
        '' +

        # Generate private ssh user key derived from 32-byte hex
        # Encrypted with passphrase matching user password
        ''
          [[ -f ${hex} ]] && cat ${hex} | 
          derive hex ${userName} |
          derive ssh "$(cat ${password})" \
          > ${user.home}/.ssh/id_ed25519
        '' +

        # Copy public ssh user key from this repo to ~/.ssh
        ''
          cat ${publicKey} \
          > ${user.home}/.ssh/id_ed25519.pub
        '' +

        # Ensure proper permissions and ownership in ~/.ssh
        ''
          [[ -f ${user.home}/.ssh/id_ed25519 ]] && 
          chmod 600 ${user.home}/.ssh/id_ed25519

          [[ -f ${user.home}/.ssh/id_ed25519.pub ]] && 
          chmod 644 ${user.home}/.ssh/id_ed25519.pub

          chmod 700 ${user.home}/.ssh
          chown -R ${user.name}:${user.group} ${user.home}/.ssh
        '' +

        ''
          if [[ -f ${hex} ]]; then 
            mkdir -p /run/user
            mkpasswd -m sha-512 -S $(cat ${hex} | cut -c 1-16) $(cat ${password}) \
            > /run/user/${userName}
            chmod 600 /run/user/${userName}
          fi
        '';

        text = concatMapStrings perUser everyone;
        path = [ perSystem.self.derive ];

      in mkAfter "${mkScript { inherit text path ; }}";

    };


    # Add user passwords to agenix
    age.secrets = let 

      # Include all user password.age files as an agenix secret as user-password
      userKeys = genAttrs 
        (map (userName: "${userName}-key") (attrNames flake.users))
        (secretName: let userName = removeSuffix "-key" secretName; in {
          rekeyFile = flake + /users/${userName}/id_ed25519.age; 
        });

      # Include all user password.age files as an agenix secret as user-password
      userPasswords = genAttrs 
        (map (userName: "${userName}-password") (attrNames flake.users))
        (secretName: let userName = removeSuffix "-password" secretName; in {
          rekeyFile = flake + /users/${userName}/password.age; 
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

    in userKeys // userPasswords // userHashedPasswords;

  };

}
