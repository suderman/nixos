{ config, flake, inputs, perSystem, ... }: {

  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  age.rekey = with config.networking; {
    # hostPubkey = "...";
    masterIdentities = [ /tmp/id_age ];
    storageMode = "local";
    localStorageDir = flake + /hosts/${hostName}/secrets;
    generatedSecretsDir = flake + /hosts/${hostName}/secrets;
  };

  environment.systemPackages = [
    perSystem.agenix-rekey.default
  ];

  environment.etc = {
    # "ssh/ssh_host_ed25519_key" = {
    #   source = ../../state/sim_ssh_host_ed25519_key;
    #   mode = "0600";
    #   user = "root";
    #   group = "root";
    # };
    # "ssh/ssh_host_rsa_key" = {
    #   source = ../../state/sim_ssh_host_rsa_key;
    #   mode = "0600";
    #   user = "root";
    #   group = "root";
    # };
  };

  services.openssh.hostKeys = [{
    type = "ed25519";
    path = "/etc/ssh/ssh_host_ed25519_key";
  } {
    type = "rsa"; bits = 4096;
    path = "/etc/ssh/ssh_host_rsa_key";
  }];

}
