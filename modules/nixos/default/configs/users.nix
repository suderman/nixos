{
  config,
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  # User names with home-manager config
  userNames = builtins.attrNames (config.home-manager.users or {});
in {
  # Update users with details found in flake.users
  users.users = let
    # Filter list of groups to only those which exist
    ifTheyExist = groups:
      builtins.filter
      (group: builtins.hasAttr group config.users.groups)
      groups;

    # Get a user by name from the flake
    flakeUser = name: rec {
      inherit name;
      user = flake.users."${name}" or {};
      openssh = user.openssh or {};
      extraGroups = (user.extraGroups or []) ++ ifTheyExist ["media" "photos"];
    };

    # Each user account found in flake.users
    userAccounts = lib.genAttrs userNames (name: let
      u = flakeUser name;
    in
      u.user
      // {
        inherit (u) extraGroups openssh;
        hashedPasswordFile =
          if config.users.users."${u.name}".password == null
          then "/run/user/${u.name}"
          else null; # generated in activation script
      });

    # Special case for flake.users.root
    rootAccount = let
      u = flakeUser "root";
    in {
      "${u.name}" =
        u.user
        // {
          inherit (u) openssh;
          hashedPasswordFile =
            if config.users.users."${u.name}".password == null
            then "/run/user/${u.name}"
            else null; # generated in activation script
        };
    };
  in
    userAccounts // rootAccount;

  # Disallow modifying users outside of this config
  users.mutableUsers = false;

  # Everybody can use zsh
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # Include all user password.age files as an agenix secret as user-password
  age.secrets =
    lib.genAttrs
    (map (userName: "${userName}-password") (builtins.attrNames flake.users))
    (secretName: let
      userName = lib.removeSuffix "-password" secretName;
    in {
      rekeyFile = flake + /users/${userName}/password.age;
    });

  # Hash user password & write SSH keys to each ~/.ssh directory
  system.activationScripts = let
    inherit (lib) concatMapStrings mkAfter;
    inherit (perSystem.self) mkScript;
    rotation = flake.lib.identityRotation // {inherit (config.identityRotation) active;};
    inherit (config.identityRotation) currentHexPath hexPath nextHexPath;

    # All users in this configuration including root
    everyone = userNames ++ ["root"];

    usermeta = name: rec {
      # Get user from nixos configuration
      user = config.users.users.${name};

      # Public ssh user key derived from 32-byte hex
      publicKey = flake + /users/${name}/id_ed25519.pub;
      nextPublicKey = rotation.nextPath publicKey;

      # Public age id derived from 32-byte hex
      publicId = flake + /users/${name}/id_age.pub;
      nextPublicId = rotation.nextPath publicId;

      # Password encrypted with age identity
      password = config.age.secrets."${name}-password".path;
    };
  in {
    # Hash user password and save to /run/user
    agenixInstall.text = let
      perUser = userName: let
        inherit (usermeta userName) user password;
      in
        # bash
        ''
          # Hash user password and store as file in /run/user
          if [[ -f ${hexPath} ]]; then
            mkdir -p /run/user
            mkpasswd -m sha-512 -S $(cut -c 1-16<${hexPath}) $(cat ${password}) \
            >/run/user/${userName}
            chmod 600 /run/user/${userName}
          fi
        '';

      text = concatMapStrings perUser everyone;
      path = [pkgs.mkpasswd];
    in
      mkAfter "${mkScript {inherit text path;}}";

    # Write SSH keys to each ~/.ssh directory
    users.text = let
      perUser = userName: let
        inherit (builtins) dirOf;
        inherit (usermeta userName) user publicId publicKey nextPublicId nextPublicKey password;
        sshDir = "${user.home}/.ssh";
        ageDir = "${user.home}/.config/age";
      in
        # bash
        ''
          # Copy public age id from this repo to ~/.config/age
          install -o ${user.name} -g ${user.group} -m 700 -d ${dirOf ageDir} ${ageDir}
          cat ${publicId} >${ageDir}/id_age.pub

          write_age_identity() {
            local root="$1" private_key="$2" public_key="$3"
            derive hex ${userName} <"$root" | derive age >"$private_key"
            if [[ "$(derive public <"$private_key" | xargs)" != "$(xargs <"$public_key")" ]]; then
              rm -f "$private_key"
              return 1
            fi
          }

          # Generate private age id derived from 32-byte hex
          if [[ -f ${currentHexPath} ]]; then
            write_age_identity ${currentHexPath} ${ageDir}/id_age ${ageDir}/id_age.pub
          fi

          ${lib.optionalString rotation.active ''
            cat ${nextPublicId} >${ageDir}/id_age.next.pub
            test -f ${nextHexPath}
            write_age_identity ${nextHexPath} ${ageDir}/id_age.next ${ageDir}/id_age.next.pub
          ''}
          ${lib.optionalString (!rotation.active) ''
            rm -f ${ageDir}/id_age.next ${ageDir}/id_age.next.pub
          ''}

          # Ensure proper permissions and ownership
          [[ -f ${ageDir}/id_age ]] && chmod 600 ${ageDir}/id_age
          [[ -f ${ageDir}/id_age.pub ]] && chmod 644 ${ageDir}/id_age.pub
          [[ -f ${ageDir}/id_age.next ]] && chmod 600 ${ageDir}/id_age.next
          [[ -f ${ageDir}/id_age.next.pub ]] && chmod 644 ${ageDir}/id_age.next.pub
          chown -R ${user.name}:${user.group} ${ageDir}

          # Copy public ssh user key from this repo to ~/.ssh
          install -o ${user.name} -g ${user.group} -m 700 -d ${sshDir}
          cat ${publicKey} >${sshDir}/id_ed25519.pub

          write_ssh_identity() {
            local root="$1" private_key="$2" public_key="$3" verify_key
            verify_key="$(mktemp ${sshDir}/id_ed25519.verify.XXXXXX)"
            derive hex ${userName} <"$root" | derive ssh >"$verify_key"
            if ! sshed verify-pair "$verify_key" "$public_key"; then
              rm -f "$verify_key" "$private_key"
              return 1
            fi
            rm -f "$verify_key"
            derive hex ${userName} <"$root" |
              derive ssh "$(cat ${password})" >"$private_key"
          }

          # Generate passphrase-protected SSH identities after public-key validation.
          if [[ -f ${currentHexPath} ]]; then
            write_ssh_identity ${currentHexPath} ${sshDir}/id_ed25519 ${sshDir}/id_ed25519.pub
          fi

          ${lib.optionalString rotation.active ''
            cat ${nextPublicKey} >${sshDir}/id_ed25519.next.pub
            test -f ${nextHexPath}
            write_ssh_identity ${nextHexPath} ${sshDir}/id_ed25519.next ${sshDir}/id_ed25519.next.pub
          ''}
          ${lib.optionalString (!rotation.active) ''
            rm -f ${sshDir}/id_ed25519.next ${sshDir}/id_ed25519.next.pub
          ''}

          # Ensure proper permissions and ownership
          [[ -f ${sshDir}/id_ed25519 ]] && chmod 600 ${sshDir}/id_ed25519
          [[ -f ${sshDir}/id_ed25519.pub ]] && chmod 644 ${sshDir}/id_ed25519.pub
          [[ -f ${sshDir}/id_ed25519.next ]] && chmod 600 ${sshDir}/id_ed25519.next
          [[ -f ${sshDir}/id_ed25519.next.pub ]] && chmod 644 ${sshDir}/id_ed25519.next.pub
          chown -R ${user.name}:${user.group} ${sshDir}
        '';

      text = concatMapStrings perUser everyone;
      path = [perSystem.self.derive perSystem.self.sshed];
    in
      mkAfter "${mkScript {inherit text path;}}";
  };
}
