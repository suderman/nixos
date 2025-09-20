{
  config,
  lib,
  flake,
  ...
}: {
  # https://github.com/ryantm/agenix
  age = {
    identityPaths =
      if builtins.hasAttr "home" config
      then ["${config.home.homeDirectory}/.config/age/id_age"]
      else ["${config.persist.storage.path}/etc/ssh/ssh_host_ed25519_key"];

    # https://github.com/oddlama/agenix-rekey
    rekey = let
      inherit (config.networking) hostName;
      username = config.home.username or "";
      target =
        lib.concatStringsSep "-"
        (builtins.filter (s: s != "") [hostName username]);
    in {
      # Master identity decrypted to /tmp/id_age for rekeying
      # > agenix unlock
      masterIdentities = [/tmp/id_age /tmp/id_age_];

      # Public ssh host key derived from 32-byte hex
      # > nixos generate
      hostPubkey = let
        inherit (builtins) pathExists readFile;
        sshPub = flake + /hosts/${hostName}/ssh_host_ed25519_key.pub;
        agePub = flake + /users/${username}/id_age.pub;
      in
        if pathExists agePub
        then readFile agePub
        else
          (
            if pathExists sshPub
            then readFile sshPub
            else readFile (flake + /id_age.pub)
          );

      storageMode = "local";
      localStorageDir = flake + /secrets/${target};
      generatedSecretsDir = flake + /secrets/${target};
    };
  };
}
