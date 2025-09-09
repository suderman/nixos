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

  # Path to private and public ssh key
  sshKey = "${cfg.dataDir}/beszel_data/id_ed25519";
  sshPubKey = flake + /users/beszel/id_ed25519.pub;
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
      hex = config.age.secrets.hex.path;

      # Derive ssh key for beszel user
      text =
        ''
          mkdir -p $(dirname ${sshKey})
          cd $(dirname ${sshKey})
        ''
        +
        # Copy public ssh user key from this repo
        ''
          cat ${sshPubKey} > ${sshKey}.pub
        ''
        +
        # Derive private ssh user key and verify
        ''
          if [[ -f ${hex} ]]; then
            cat ${hex} |
            derive hex beszel |
            derive ssh > ${sshKey}
            sshed verify || rm -f ${sshKey}
          fi
        ''
        +
        # Ensure proper permissions and ownership
        ''
          [[ -f ${sshKey} ]] && chmod 600 ${sshKey}
          [[ -f ${sshKey}.pub ]] && chmod 644 ${sshKey}.pub
          chown beszel:beszel ${sshKey}*
        '';

      path = [perSystem.self.derive perSystem.self.sshed];
    in
      mkAfter "${mkScript {inherit text path;}}";
  };
}
