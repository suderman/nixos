# Configure agenix to work with derived identity and ssh keys
{
  config,
  lib,
  hostName,
  pkgs,
  perSystem,
  flake,
  ...
}: {
  imports = [
    flake.inputs.agenix.nixosModules.default
    flake.inputs.agenix-rekey.nixosModules.default
    (flake + /secrets)
  ];

  # 32-byte hex imported from QR code
  # > import-id
  age.secrets.hex.rekeyFile = flake + /secrets/hex.age;

  environment.etc = lib.optionalAttrs config.identityRotation.active {
    "identity-rotation/prepared".text =
      builtins.hashFile "sha256" (flake + /secrets/rotation/next/artifacts.json);
  };

  # Add /mnt/main/storage/etc/ssh/ssh_host_ed25519_key.pub and /etc/machine-id
  system.activationScripts.etc.text = let
    rotation = flake.lib.identityRotation // {inherit (config.identityRotation) active;};
    inherit (config.identityRotation) hexPath nextHexPath;
    storage = config.persist.storage.path;
    currentHostKey = "${storage}/etc/ssh/ssh_host_ed25519_key";
    currentHostPublicKey = flake + /hosts/${hostName}/ssh_host_ed25519_key.pub;
    nextHostKey = "${currentHostKey}.next";
    nextHostPublicKey = rotation.nextPath currentHostPublicKey;
    path = [perSystem.self.derive perSystem.self.sshed];
    text =
      # bash
      ''
        # Copy public ssh host key from this repo to /mnt/main/storage
        mkdir -p ${storage}/etc/ssh
        cat ${currentHostPublicKey} >${currentHostKey}.pub
        chmod 644 ${currentHostKey}.pub
        # Ensure private ssh host key (even if an empty file) exists too
        touch ${currentHostKey}
        chmod 600 ${currentHostKey}
      ''
      + lib.optionalString rotation.active
      # bash
      ''
        # Prepare the next deterministic host key without replacing the current key.
        test -f ${nextHexPath}
        cat ${nextHostPublicKey} >${nextHostKey}.pub
        next_tmp="$(mktemp ${nextHostKey}.tmp.XXXXXX)"
        trap 'rm -f "$next_tmp"' EXIT
        derive hex ${hostName} <${nextHexPath} | derive ssh >"$next_tmp"
        chmod 600 "$next_tmp"
        sshed verify-pair "$next_tmp" ${nextHostKey}.pub
        mv "$next_tmp" ${nextHostKey}
        trap - EXIT
        chmod 644 ${nextHostKey}.pub
      ''
      + lib.optionalString (!rotation.active)
      # bash
      ''
        # Finalize by promoting a prepared key that matches the new canonical public key.
        if [[ -f ${nextHostKey} ]] &&
           sshed verify-pair ${nextHostKey} ${currentHostKey}.pub &&
           ! sshed verify-pair ${currentHostKey} ${currentHostKey}.pub; then
          mv ${nextHostKey} ${currentHostKey}
          chmod 600 ${currentHostKey}
        fi
        rm -f ${nextHostKey} ${nextHostKey}.pub
      ''
      +
      # bash
      ''
        # Derive machine id from decrypted hex (if agenix decrypting)
        echo 00000000000000000000000000000000 >/etc/machine-id
        [[ -f ${hexPath} ]] && derive hex ${hostName} 32 <${hexPath} >/etc/machine-id
        chmod 444 /etc/machine-id
      '';
  in
    lib.mkAfter "${perSystem.self.mkScript {inherit path text;}}";

  services.openssh.hostKeys = let
    rotation = flake.lib.identityRotation // {inherit (config.identityRotation) active;};
    current = {
      # ed25519 derived from hex
      path = "${config.persist.storage.path}/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    };
    next = current // {path = "${current.path}.next";};
    ed25519 =
      if !rotation.active
      then [current]
      else if config.identityRotation.targetState == "current"
      then [current]
      else if config.identityRotation.targetState == "bridge"
      then [current next]
      else [next current];
  in
    ed25519
    ++ [
      {
        # rsa automatically generated
        path = "${config.persist.storage.path}/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];

  # Helps bootstrap a new system with expected SSH private key
  # When needed, listens on port 12345 for a key to be sent via netcat
  # Also updates the /etc/issue with the command required
  systemd.services.sshed = {
    description = "Verify and/or receive SSH host key via sshed receive";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    before = ["sshd.service"];
    requiredBy = ["sshd.service"];
    serviceConfig.Type = "oneshot";
    path = [
      perSystem.self.sshed
      perSystem.self.ipaddr
      pkgs.hostname
      pkgs.systemd
    ];
    script = let
      rotation = flake.lib.identityRotation // {inherit (config.identityRotation) active;};
      sshDir = "${config.persist.storage.path}/etc/ssh";
      currentKey = "${sshDir}/ssh_host_ed25519_key";
      nextKey = "${currentKey}.next";
    in ''
      # Verify private ssh key matches public key
      if ! sshed verify-pair ${currentKey} ${currentKey}.pub; then

        # Wait for IP and hostname to be available
        while [[ -z "$(ipaddr lan)" ]]; do sleep 1; done
        while [[ -z "$(hostname)" ]]; do sleep 1; done

        # Append issue with sshed send command including IP address
        rm /etc/issue && cp /etc/static/issue /etc/issue
        echo "SSH host keys INVALID" | tee -a /etc/issue
        echo "Send missing private SSH key from another computer with the following command:" >>/etc/issue
        echo -e "\n> sshed send $(hostname) $(ipaddr lan)\n" >>/etc/issue

        # Wait for private ssh key to be received and then reboot
        sshed receive
        systemctl reboot

      fi

      ${lib.optionalString rotation.active ''
        if ! sshed verify-pair ${nextKey} ${nextKey}.pub; then
          echo "Next SSH host key INVALID" >&2
          exit 1
        fi
      ''}

      echo "SSH host keys VALID"
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
}
