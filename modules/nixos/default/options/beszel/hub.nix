# services.beszel.enable = true;
{
  config,
  lib,
  perSystem,
  flake,
  ...
}: let
  cfg = config.services.beszel;
  inherit (builtins) toString;
  inherit (lib) mkIf mkEnableOption mkOption types mkAfter;
  port = 8090;
  inherit (flake.lib) identityRotation;

  # Path to private and public ssh key
  sshKey = "${cfg.dataDir}/beszel_data/id_ed25519";
  sshPubKey = flake + /users/beszel/id_ed25519.pub;
  currentSshKey = "${sshKey}.current";
  nextSshKey = "${sshKey}.next";
  nextSshPubKey = identityRotation.nextPath sshPubKey;
in {
  options.services.beszel.enable = mkEnableOption "Beszel hub";

  config = mkIf cfg.enable {
    # tmpfiles.directories = [{
    #   target = "${cfg.dataDir}/hub";
    #   user = "beszel";
    # }];

    systemd.services.beszel-hub = {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        User = "beszel";
        Group = "beszel";
        Restart = "always";
        # WorkingDirectory = "${cfg.dataDir}/hub";
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/beszel-hub serve --http '0.0.0.0:${toString port}'";
        RestartSec = "5";
      };
      startLimitIntervalSec = 180;
      startLimitBurst = 30;
    };

    services.traefik.proxy."beszel" = port;

    # Write beszel ssh keys
    system.activationScripts.users.text = let
      inherit (perSystem.self) mkScript;
      inherit (config.identityRotation) currentHexPath nextHexPath;
      selectedSshKey =
        if identityRotation.useNext "identities" "beszel"
        then nextSshKey
        else currentSshKey;
      selectedSshPubKey =
        if identityRotation.useNext "identities" "beszel"
        then "${nextSshKey}.pub"
        else sshPubKey;

      # Derive ssh key for beszel user
      text =
        ''
          mkdir -p $(dirname ${sshKey})
          cd $(dirname ${sshKey})

          write_beszel_identity() {
            local root="$1" private_key="$2" public_key="$3"
            derive hex beszel <"$root" | derive ssh >"$private_key"
            sshed verify-pair "$private_key" "$public_key"
          }
        ''
        +
        # Copy public ssh user key from this repo
        ''
          cat ${sshPubKey} > ${sshKey}.pub
        ''
        +
        # Derive private ssh user key and verify
        ''
          if [[ -f ${currentHexPath} ]]; then
            write_beszel_identity ${currentHexPath} ${sshKey} ${sshKey}.pub
          fi

          ${lib.optionalString identityRotation.active ''
            cp ${sshKey} ${currentSshKey}
            cat ${nextSshPubKey} >${nextSshKey}.pub
            test -f ${nextHexPath}
            write_beszel_identity ${nextHexPath} ${nextSshKey} ${nextSshKey}.pub

            cp ${selectedSshKey} ${sshKey}
            cat ${selectedSshPubKey} >${sshKey}.pub
          ''}
          ${lib.optionalString (!identityRotation.active) ''
            rm -f ${currentSshKey} ${nextSshKey} ${nextSshKey}.pub
          ''}
        ''
        +
        # Ensure proper permissions and ownership
        ''
          [[ -f ${sshKey} ]] && chmod 600 ${sshKey}
          [[ -f ${sshKey}.pub ]] && chmod 644 ${sshKey}.pub
          [[ -f ${currentSshKey} ]] && chmod 600 ${currentSshKey}
          [[ -f ${nextSshKey} ]] && chmod 600 ${nextSshKey}
          [[ -f ${nextSshKey}.pub ]] && chmod 644 ${nextSshKey}.pub
          chown beszel:beszel ${sshKey}*
        '';

      path = [perSystem.self.derive perSystem.self.sshed];
    in
      mkAfter "${mkScript {inherit text path;}}";
  };
}
