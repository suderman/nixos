{ config, flake, inputs, perSystem, pkgs, lib, ... }: {

  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  # Configure agenix to work with derived identity and ssh keys
  config = {

    # agenix-rekey setup for this host, secrets in repo
    age.rekey = with config.networking; {
      hostPubkey = config.services.openssh.publicKey;
      masterIdentities = [ /tmp/id_age /tmp/id_age_ ];
      storageMode = "local";
      localStorageDir = flake + /secrets/rekeyed/${hostName};
      generatedSecretsDir = flake + /secrets/generated/${hostName};
    };

    # 32-byte hex imported from QR code
    age.secrets = {
      hex.rekeyFile = flake + /secrets/hex.age; 
    };

    # Manually add public ssh ed25519 key
    environment.etc = {
      "ssh/ssh_host_ed25519_key.pub" = {
        source = config.services.openssh.publicKey;
        mode = "0644";
        user = "root";
        group = "root";
      };
    };

    # Manually add private ssh ed25519 key
    services.openssh.extraConfig = ''
      HostKey /etc/ssh/ssh_host_ed25519_key
    '';

    # Because of the above, manually specify derived key as age identity
    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    environment.systemPackages = [
      perSystem.agenix-rekey.default
      perSystem.self.ipaddr
      perSystem.self.derive
      perSystem.self.sshed
      pkgs.curl
      pkgs.openssh
      pkgs.netcat
      pkgs.iproute2
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
        cd /etc/ssh 
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
