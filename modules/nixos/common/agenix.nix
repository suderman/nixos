{ flake, inputs, perSystem, config, lib, pkgs, hostName, ... }: {

  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  # Configure agenix to work with derived identity and ssh keys
  config = {

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

        # Public ssh host key derived from 32-byte hex
        # > sshed generate
        hostPubkey = builtins.readFile (
          flake + /hosts/${hostName}/ssh_host_ed25519_key.pub
        );

        # Master identity decrypted to /tmp/id_age for rekeying
        # > unlock-id
        masterIdentities = [ /tmp/id_age /tmp/id_age_ ];

        # Store rekeyed & generated secrets in repo
        storageMode = "local";
        # localStorageDir = flake + /secrets/rekeyed/${hostName};
        # generatedSecretsDir = flake + /secrets/generated/${hostName};
        localStorageDir = flake + /hosts/${hostName}/secrets;
        generatedSecretsDir = flake + /hosts/${hostName}/generated;
      };

    };

    # Add /persist/etc/ssh/ssh_host_ed25519_key.pub and /etc/machine-id
    system.activationScripts.etc.text = let

      inherit (config.age.rekey) hostPubkey;
      hex = config.age.secrets.hex.path;
      path = [ perSystem.self.derive ];

      # Copy public ssh host key from this repo to /persist
      text = ''
        mkdir -p /persist/etc/ssh
        echo "${hostPubkey}" > /persist/etc/ssh/ssh_host_ed25519_key.pub
        chmod 644 /persist/etc/ssh/ssh_host_ed25519_key.pub
      '' + 

      # Derive machine id from decrypted hex (if agenix decrypting)
      ''
        [[ -f ${hex} ]] && cat ${hex} | 
        derive hex ${hostName} 32 > /etc/machine-id
        chmod 444 /etc/machine-id
      ''; 

    in lib.mkAfter "${perSystem.self.mkScript { inherit path text; }}";


    # Tell sshd that ssh host keys are found in /persist
    services.openssh.hostKeys = [{
      path = "/persist/etc/ssh/ssh_host_ed25519_key"; # derived and side-loaded
      type = "ed25519";
    } {
      path = "/persist/etc/ssh/ssh_host_rsa_key"; # automatically generated
      type = "rsa";
      bits = 4096;
    }];

    # Helps bootstrap a new system with expected SSH private key
    # When needed, listens on port 12345 for a key to be sent via netcat
    # Also updates the /etc/issue with the command required
    systemd.services.sshed = {
      description = "Verify and/or receive SSH host key via sshed receive";
      wantedBy = [ "multi-user.target" ]; 
      after = [ "network.target" ]; 
      before = [ "sshd.service" ]; 
      requiredBy = [ "sshd.service" ]; 
      serviceConfig.Type = "oneshot";
      path = [ 
        perSystem.self.sshed 
        perSystem.self.ipaddr 
        pkgs.hostname 
        pkgs.systemd 
      ];
      script = ''
        # Verify private ssh key matches public key
        cd /persist/etc/ssh 
        if sshed verify; then
          echo "SSH host keys VALID"
        else

          # Wait for IP and hostname to be available
          while [[ -z "$(ipaddr lan)" ]]; do sleep 1; done
          while [[ -z "$(hostname)" ]]; do sleep 1; done

          # Append issue with sshed send command including IP address
          rm /etc/issue && cp /etc/static/issue /etc/issue
          echo "SSH host keys INVALID" | tee -a /etc/issue
          echo "Send missing private SSH key from another computer with the following command:" >> /etc/issue
          echo -e "\n> sshed send $(hostname) $(ipaddr lan)\n" >> /etc/issue

          # Wait for private ssh key to be received and then reboot
          sshed receive
          systemctl reboot

        fi
      '';
    };

    # These packages should be available to the whole system
    environment.systemPackages = [
      perSystem.agenix-rekey.default
      perSystem.self.derive
      perSystem.self.ipaddr
      perSystem.self.sshed
      pkgs.curl
      pkgs.iproute2
      pkgs.netcat
      pkgs.openssh
    ];

  };

}
