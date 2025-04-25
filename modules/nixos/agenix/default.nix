{ flake, inputs, hostName, lib, ... }: {

  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  # https://github.com/ryantm/agenix
  age = {

    # 32-byte hex imported from QR code
    # > import-id
    secrets.hex.rekeyFile = flake + /hex.age;

    # Private ssh host key must be side-loaded/persisted to decrypt secrets
    # > sshed send hostName IP
    identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    # https://github.com/oddlama/agenix-rekey
    rekey = {

      # Master identity decrypted to /tmp/id_age for rekeying
      # > unlock-id
      masterIdentities = [ /tmp/id_age /tmp/id_age_ ];

      # Store rekeyed & generated secrets in repo
      storageMode = "local";
      localStorageDir = flake + /modules/nixos/agenix/${hostName};
      generatedSecretsDir = flake + /modules/nixos/agenix/${hostName};

    };

  };

}
