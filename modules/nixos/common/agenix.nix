{ flake, inputs, perSystem, config, lib, pkgs, hostName, ... }: {

  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  # Configure agenix to work with derived identity and ssh keys
  config = {

    # agenix-rekey setup for this host, secrets in repo
    age.rekey = {
      hostPubkey = flake.lib.trimFile( flake + /hosts/${hostName}/ssh_host_ed25519_key.pub );
      masterIdentities = [ /tmp/id_age /tmp/id_age_ ];
      storageMode = "local";
      localStorageDir = flake + /secrets/rekeyed/${hostName};
      generatedSecretsDir = flake + /secrets/generated/${hostName};
    };

    # Derive secrets from hex
    system.activationScripts.etc.text = let
      inherit (perSystem.self) mkScript derive;
      inherit (config.age.rekey) hostPubkey;
      hex = config.age.secrets.hex.path;
      script = mkScript { path = [ derive ]; text = ''
        # Write public ssh host key
        mkdir -p /persist/etc/ssh
        echo ${hostPubkey} > /persist/etc/ssh/ssh_host_ed25519_key.pub
        chown 644 /persist/etc/ssh/ssh_host_ed25519_key.pub

        # Derive machine id
        [[ -f ${hex} ]] && 
        cat ${hex} | 
        derive hex ${hostName} | 
        cut -c1-32 > /etc/machine-id
        chown 444 /etc/machine-id
      ''; };
    in lib.mkAfter "${script}";

    # Private ssh host key must be side-loaded/persisted to decrypt secrets
    age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    # Tell sshd that ssh host keys are found in /persist
    services.openssh.hostKeys = [{
      path = "/persist/etc/ssh/ssh_host_ed25519_key"; # derived and side-loaded
      type = "ed25519";
    } {
      path = "/persist/etc/ssh/ssh_host_rsa_key"; # automatically generated
      type = "rsa";
      bits = 4096;
    }];

    # 32-byte hex imported from QR code
    age.secrets = {
      hex.rekeyFile = flake + /secrets/hex.age; 
    };

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

  };

}
