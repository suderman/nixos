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
      masterIdentities = [ /tmp/id_age /tmp/id_age_ ];
      storageMode = "local";
      localStorageDir = flake + /secrets/${hostName};
      generatedSecretsDir = flake + /secrets/${hostName};
    };

    age.secrets = {
      key.rekeyFile = flake + /secrets/key.age; 
    };

    # Manually add public ssh ed25519 key
    environment.etc = {
      "ssh/ssh_host_ed25519_key.pub" = {
        source = config.networking.hostPubkey;
        mode = "0644";
        user = "root";
        group = "root";
      };
    };

    # Manually add private ssh ed25519 key
    services.openssh.extraConfig = ''
      HostKey /etc/ssh/ssh_host_ed25519_key
    '';

    # Exclude auto-generated ssh ed25519 from this list
    services.openssh.hostKeys = [{
      type = "rsa"; bits = 4096;
      path = "/etc/ssh/ssh_host_rsa_key";
    }];

    # Because of the above, manually specify derived key as age identity
    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    environment.systemPackages = [
      perSystem.agenix-rekey.default
      perSystem.self.ipaddr
      perSystem.self.derive
      perSystem.self.ssh-key
      pkgs.curl
      pkgs.openssh
      pkgs.netcat
      pkgs.iproute2 # ip
    ];

    # Helps bootstrap a new system with expected SSH private key
    # When needed, listens on port 12345 for a key to be sent via netcat
    # Also updates the /etc/issue with the command required
    systemd.services.ssh-key-loader = {
      description = "Verify and/or receive SSH host key via netcat";
      wantedBy = [ "multi-user.target" ]; 
      after = [ "network.target" ]; 
      before = [ "sshd.service" ]; 
      requiredBy = [ "sshd.service" ]; 
      serviceConfig.Type = "oneshot";
      path = [ 
        perSystem.self.ssh-key 
        perSystem.self.ipaddr 
        pkgs.hostname 
        pkgs.systemd 
      ];
      script = ''
        # Verify private ssh key matches public key
        cd /etc/ssh 
        if ssh-key verify; then
          echo "SSH host keys VALID"
        else

          # Wait for IP and hostname to be available
          while [[ -z "$(ipaddr lan)" ]]; do sleep 1; done
          while [[ -z "$(hostname)" ]]; do sleep 1; done

          # Append issue with ssh-key send command including IP address
          rm /etc/issue && cp /etc/static/issue /etc/issue
          echo "SSH host keys INVALID" | tee -a /etc/issue
          echo "Send missing private SSH key from another computer with the following command:" >> /etc/issue
          echo -e "\n> ssh-key send $(hostname) $(ipaddr lan)\n" >> /etc/issue

          # Wait for private ssh key to be received and then reboot
          ssh-key receive
          systemctl reboot

        fi
      '';
    };

  };

}
