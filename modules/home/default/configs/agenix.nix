{
  config,
  osConfig,
  flake,
  ...
}: {
  imports = [
    flake.inputs.agenix.homeManagerModules.default
    flake.inputs.agenix-rekey.homeManagerModules.default
  ];

  # https://github.com/ryantm/agenix
  age = let
    inherit (config.home) username;
    inherit (osConfig.networking) hostName;
  in {
    # secretsDir = "/run/user/${toString config.home.uid}/agenix";
    # Private ssh host key must be side-loaded/persisted to decrypt secrets
    # > sshed send hostName IP
    # identityPaths = ["${osConfig.persist.storage.path}/etc/ssh/ssh_host_ed25519_key"];
    identityPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];

    # https://github.com/oddlama/agenix-rekey
    rekey = {
      inherit (osConfig.age.rekey) masterIdentities storageMode;

      # Public ssh user key derived from 32-byte hex
      # > sshed generate
      hostPubkey = let
        inherit (builtins) pathExists readFile;
        sshPub = flake + /users/${username}/id_ed25519.pub;
        agePub = flake + /id.pub;
      in
        if pathExists sshPub
        then readFile sshPub
        else readFile agePub;

      localStorageDir = flake + /modules/nixos/secrets/${hostName}-${username};
      generatedSecretsDir = flake + /modules/nixos/secrets/${hostName}-${username};
    };
  };
}
