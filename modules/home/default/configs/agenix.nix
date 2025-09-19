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
    identityPaths = ["${config.home.homeDirectory}/.config/age/id_age"];

    # https://github.com/oddlama/agenix-rekey
    rekey = {
      inherit (osConfig.age.rekey) masterIdentities storageMode;

      # User age receipients derived from 32-byte hex
      # > nixos generate
      hostPubkey = let
        inherit (builtins) pathExists readFile;
        agePub = flake + /users/${username}/id_age.pub;
      in
        if pathExists agePub
        then readFile agePub
        else readFile (flake + /id_age.pub);

      localStorageDir = flake + /modules/nixos/secrets/${hostName}-${username};
      generatedSecretsDir = flake + /modules/nixos/secrets/${hostName}-${username};
    };
  };
}
