{
  config,
  flake,
  lib,
  ...
}: let
  inherit (flake.lib) identityRotation;
  isHome = builtins.hasAttr "home" config;
  hostName = config.networking.hostName;
  username = config.home.username or "";

  # Public key that generated ciphertext is encrypted to
  currentPub = let
    agePub = flake + /users/${username}/id_age.pub;
    sshPub = flake + /hosts/${hostName}/ssh_host_ed25519_key.pub;
  in
    if builtins.pathExists agePub
    then agePub
    else if builtins.pathExists sshPub
    then sshPub
    else flake + /secrets/id_age.pub;
  nextPub = identityRotation.nextPath currentPub;

  # Targets rotate when prepare has written their next public key
  rotating = identityRotation.active && builtins.pathExists nextPub;
  useNext = rotating && identityRotation.useNext;

  currentIdentity =
    if isHome
    then "${config.home.homeDirectory}/.config/age/id_age"
    else "${config.persist.storage.path}/etc/ssh/ssh_host_ed25519_key";
in {
  options.identityRotation = {
    active = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether this target holds both key generations during a rotation";
    };
    currentHexPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      description = "Decrypted current fleet root on NixOS targets";
    };
    nextHexPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      description = "Decrypted next fleet root on NixOS targets during a rotation";
    };
    hexPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      description = "Selected fleet root for derived machine IDs and credentials";
    };
  };

  config = {
    identityRotation = rec {
      active = rotating;
      currentHexPath =
        if isHome
        then null
        else config.age.secrets.hex.path;
      nextHexPath =
        if rotating && !isHome
        then config.age.secrets.hex-next.path
        else null;
      hexPath =
        if useNext && !isHome
        then nextHexPath
        else currentHexPath;
    };

    # https://github.com/ryantm/agenix
    age = {
      # List of recipient keys (age or ssh) used to decrypt secrets
      identityPaths =
        [currentIdentity]
        ++ lib.optional rotating (identityRotation.nextPath currentIdentity);

      secrets = lib.optionalAttrs (rotating && !isHome) {
        hex-next.rekeyFile = flake + /secrets/rotation/next/hex.age;
      };

      # Directory where secrets are symlinked to by default
      secretsDir =
        if isHome
        then "/run/user/${toString config.home.uid}/agenix"
        else "/run/agenix";

      # https://github.com/oddlama/agenix-rekey
      rekey = let
        target =
          if isHome
          then "home/${hostName}-${username}"
          else "nixos/${hostName}";
      in {
        # Master identity decrypted to /tmp/id_age for rekeying
        # > agenix unlock
        masterIdentities = [/tmp/id_age /tmp/id_age_];

        # Public ssh host key or user age identity derived from 32-byte hex
        # > nixos generate
        hostPubkey = builtins.readFile (
          if useNext
          then nextPub
          else currentPub
        );

        storageMode = "local";
        localStorageDir = flake + /secrets/${target};
        generatedSecretsDir = flake + /secrets/${target};
      };
    };
  };
}
