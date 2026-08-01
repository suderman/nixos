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
  targetCategory =
    if isHome
    then "home"
    else "nixos";
  targetName =
    if isHome
    then "${hostName}-${username}"
    else hostName;
  targetState = identityRotation.targetState targetCategory targetName;
  currentIdentity =
    if isHome
    then "${config.home.homeDirectory}/.config/age/id_age"
    else "${config.persist.storage.path}/etc/ssh/ssh_host_ed25519_key";
in {
  options.identityRotation = {
    active = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether a managed identity rotation is active";
    };
    targetState = lib.mkOption {
      type = lib.types.enum ["current" "bridge" "next"];
      readOnly = true;
      description = "Rotation state for this NixOS or Home Manager target";
    };
    currentHexPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      description = "Path to the current decrypted fleet root on NixOS targets";
    };
    nextHexPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      description = "Path to the next decrypted fleet root during rotation";
    };
    hexPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      description = "Selected decrypted fleet root on NixOS targets";
    };
  };

  config = {
    identityRotation = let
      currentHexPath =
        if isHome
        then null
        else config.age.secrets.hex.path;
      nextHexPath =
        if identityRotation.active && !isHome
        then config.age.secrets.hex-next.path
        else null;
    in {
      inherit currentHexPath nextHexPath targetState;
      inherit (identityRotation) active;
      hexPath =
        if !isHome && targetState == "next"
        then nextHexPath
        else currentHexPath;
    };

    # https://github.com/ryantm/agenix
    age = {
      # List of recipient keys (age or ssh) used to decrypt secrets
      identityPaths =
        [currentIdentity]
        ++ lib.optional identityRotation.active "${currentIdentity}.next";

      secrets = lib.optionalAttrs (identityRotation.active && !isHome) {
        hex-next.rekeyFile = flake + /secrets/rotation/next/hex.age;
      };

      # Directory where secrets are symlinked to by default
      secretsDir =
        if builtins.hasAttr "home" config
        then "/run/user/${toString config.home.uid}/agenix"
        else "/run/agenix";

      # https://github.com/oddlama/agenix-rekey
      rekey = let
        target =
          if isHome
          then "home/${hostName}-${username}"
          else "nixos/${hostName}";
        currentSshPub = flake + /hosts/${hostName}/ssh_host_ed25519_key.pub;
        currentAgePub = flake + /users/${username}/id_age.pub;
        currentPub =
          if builtins.pathExists currentAgePub
          then currentAgePub
          else if builtins.pathExists currentSshPub
          then currentSshPub
          else flake + /secrets/id_age.pub;
        selectedPub =
          if identityRotation.active && targetState == "next"
          then identityRotation.nextPath currentPub
          else currentPub;
      in {
        # Master identity decrypted to /tmp/id_age for rekeying
        # > agenix unlock
        masterIdentities =
          [/tmp/id_age /tmp/id_age_]
          ++ lib.optional identityRotation.active /tmp/id_age_next;

        # Public ssh host key derived from 32-byte hex
        # > nixos generate
        hostPubkey = builtins.readFile selectedPub;

        storageMode = "local";
        localStorageDir = flake + /secrets/${target};
        generatedSecretsDir = flake + /secrets/${target};
      };
    };
  };
}
