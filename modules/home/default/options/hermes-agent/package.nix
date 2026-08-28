{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) clientAgents dataDir localProfiles;

  # Create a hermes binary named after the agent
  clientPackageFor = name: let
    agent = cfg.agents.${name};

    # Wrap the hermes binary
    localWrapperFor = name:
      pkgs.self.mkScript {
        inherit name;
        text =
          # bash
          ''
            export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
            export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-bundle.crt"
            export HERMES_KANBAN_HOME="${dataDir}"
            export HERMES_HOME="${dataDir}"
            export HERMES_MANAGED="home-manager"
            unset HASS_TOKEN HASS_URL

            if [[ -z "''${HERMES_TUI-}" ]]; then
              if [[ -t 0 && -t 1 ]]; then
                export HERMES_TUI=1
              else
                export HERMES_TUI=0
              fi
            fi

            exec "${cfg.package}/bin/hermes" --profile "${name}" "$@"
          '';
      };

    # Run the hermes binary on another host via ssh
    remoteWrapperFor = name: sshAlias:
      pkgs.self.mkScript {
        inherit name;
        text =
          # bash
          ''
            printf -v command '%q ' "${name}" "$@"
            if [[ -t 0 && -t 1 ]]; then
              exec ssh -t "${sshAlias}" "''${command% }"
            else
              exec ssh -T "${sshAlias}" "''${command% }"
            fi
          '';
      };
  in
    if builtins.elem name localProfiles
    then localWrapperFor name
    else remoteWrapperFor name agent.client;
in {
  config = lib.mkIf cfg.enable {
    # Create the named binaries
    services.hermes-agent.packages = lib.listToAttrs (map (
        name: {
          inherit name;
          value = clientPackageFor name;
        }
      )
      clientAgents);

    # Add them all to the path
    home.packages = builtins.attrValues cfg.packages;
  };
}
