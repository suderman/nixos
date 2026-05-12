{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) clientAgents dataDir localClientAgents;

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
            export HERMES_HOME="${dataDir}/${name}"
            export HERMES_TUI="''${HERMES_TUI:-1}"

            set -a
            [[ -f "${dataDir}/.env" ]] && . "${dataDir}/.env"
            [[ -f "${dataDir}/${name}/.env" ]] && . "${dataDir}/${name}/.env"
            set +a

            exec "${cfg.package}/bin/hermes" "$@"
          '';
      };

    # Run the hermes binary on another host via ssh
    remoteWrapperFor = name: sshAlias:
      pkgs.self.mkScript {
        inherit name;
        text =
          # bash
          ''
            exec ssh -t "${sshAlias}" "${name}" "$@"
          '';
      };
  in
    if builtins.elem name localClientAgents
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
