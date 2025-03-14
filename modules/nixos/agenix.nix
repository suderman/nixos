{ config, flake, inputs, perSystem, pkgs, lib, ... }: let
  inherit (lib) makeBinPath mkOption types;

  ssh-keyget = pkgs.writeScriptBin "ssh-keyget" ''
    #!/usr/bin/env bash
    export PATH=${makeBinPath [pkgs.netcat perSystem.self.to-public]}:$PATH
    echo "ssh-keysend $(lan-ip)"
    nc -l -N 12345 > /etc/ssh/key
    if [[ "ssh-ed25519" == "$(cat /etc/ssh/key | to-public | cut -d' ' -f1)" ]]; then
      mv /etc/ssh/key /etc/ssh/ssh_host_ed25519_key
      chmod 600 /etc/ssh/ssh_host_ed25519_key
      systemctl restart sshd
      echo "Success: valid ed25519 key"
    else
      echo "Error: invalid ed25519 key"
    fi
  '';

  lan-ip = pkgs.writeScriptBin "lan-ip" ''
    #!/usr/bin/env bash
    export PATH=${makeBinPath [pkgs.iproute2]}:$PATH
    lan="$(ip -4 a | awk '/state UP/{flag=1} flag && /inet /{split($2, ip, "/"); print ip[1]; exit}')"
    vpn="$(ip -4 a | awk '/tailscale0/{flag=1} flag && /inet /{split($2, ip, "/"); print ip[1]; exit}')"
    echo "$([ -z "$vpn" ] || [[ $lan == 10.0.2.* ]] && echo "$vpn" || echo "$lan")"
  '';

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
      localStorageDir = flake + /hosts/${hostName}/secrets;
      generatedSecretsDir = flake + /hosts/${hostName}/secrets;
    };

    age.secrets = {
      seed.rekeyFile = flake + /seed.age; 
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
      pkgs.curl
      pkgs.openssh
      pkgs.netcat
      pkgs.iproute2 # ip
      ssh-keyget
      lan-ip
    ];

    networking.firewall.allowedTCPPorts = [ 12345 ];

    systemd.services.ssh-keyget = {
      enable = true;
      description = "Receive SSH host key";
      after = [ "network.target" ]; 
      wantedBy = [ "multi-user.target" ]; 
      serviceConfig.Type = "oneshot";
      path = [ ssh-keyget perSystem.self.to-public ];
      script = ''
        while true; do
          if [[ -f /etc/ssh/ssh_host_ed25519_key ]] && [[ -f /etc/ssh/ssh_host_ed25519_key.pub ]]; then
            if [[ "$(cat /etc/ssh/ssh_host_ed25519_key | to-public)" == "$(cat /etc/ssh/ssh_host_ed25519_key.pub)" ]]; then
              echo "VALID ssh host key"
              break
            else
              echo "INVALID ssh host key"
              ssh-keyget
            fi
          fi
          sleep 1
        done
      '';
    };

  };

}
