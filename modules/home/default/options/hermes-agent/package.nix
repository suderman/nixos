{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) dataDir;
in {
  config = lib.mkIf cfg.enable {
    # Create custom cli package for each agent by name
    services.hermes-agent.packages = lib.listToAttrs (map (
        name: {
          inherit name;
          value = pkgs.self.mkScript {
            inherit name;
            text =
              # bash
              ''
                export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
                export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-bundle.crt"
                export HERMES_HOME="${dataDir}/${name}"

                set -a
                [[ -f "${dataDir}/.env" ]] && . "${dataDir}/.env"
                [[ -f "${dataDir}/${name}/.env" ]] && . "${dataDir}/${name}/.env"
                set +a

                exec "${cfg.package}/bin/hermes" "$@"
              '';
          };
        }
      )
      cfg.agents);

    # Add all these agent packages to the path
    home.packages = builtins.attrValues cfg.packages;
  };
}
