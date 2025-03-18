{ config, flake, inputs, perSystem, pkgs, lib, ... }: let
  inherit (lib) makeBinPath mkOption types;
in {

  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  options.networking = {
    hostPubkey = mkOption { type = types.path; };
    hostPrvkey = mkOption { type = types.path; };
  };

  config = {

    age.rekey = with config.networking; {
      inherit hostPubkey;
      masterIdentities = [ /tmp/id_age /tmp/id_age_prev ];
      storageMode = "local";
      localStorageDir = flake + /secrets/${hostName};
      generatedSecretsDir = flake + /secrets/${hostName};
    };

    age.secrets = {
      key.rekeyFile = flake + /secrets/key.age; 
    };

    environment.etc = {
      "ssh/ssh_host_ed25519_key.pub" = {
        source = config.networking.hostPubkey;
        mode = "0644";
        user = "root";
        group = "root";
      };
    };

    services.openssh.hostKeys = [{
      type = "ed25519";
      path = "/etc/ssh/ssh_host_ed25519_key";
    } {
      type = "rsa"; bits = 4096;
      path = "/etc/ssh/ssh_host_rsa_key";
    }];


    environment.systemPackages = [
      perSystem.agenix-rekey.default
      perSystem.self.ipaddr
      pkgs.curl
      pkgs.openssh
      pkgs.netcat
      pkgs.iproute2 # ip
    ];

    networking.firewall.allowedTCPPorts = [ 12345 ];

    systemd.services.ssh-key-receieve = {
      enable = true;
      description = "Receive SSH host key";
      after = [ "network.target" ]; 
      wantedBy = [ "multi-user.target" ]; 
      serviceConfig.Type = "oneshot";
      path = [ perSystem.self.ssh-key ];
      script = "cd /etc/ssh && ssh-key receive reboot";
    };

  };

}
