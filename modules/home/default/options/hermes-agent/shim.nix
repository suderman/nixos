{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit (config.lib.hermes-agent) agentNames dataDir localProfiles;

  hermesShim = pkgs.self.mkScript {
    name = "hermes";
    text = ''
      export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
      export REQUESTS_CA_BUNDLE="/etc/ssl/certs/ca-bundle.crt"
      export HERMES_HOME="${dataDir}"
      export HERMES_KANBAN_HOME="${dataDir}"
      export HERMES_MANAGED="home-manager"
      unset HASS_TOKEN HASS_URL

      exec "${cfg.package}/bin/hermes" "$@"
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(builtins.elem "hermes" agentNames);
        message = "services.hermes-agent.agents cannot include 'hermes'; that binary name is reserved.";
      }
      {
        assertion =
          lib.all (
            name: name != "default" && builtins.match "^[a-z0-9][a-z0-9_-]{0,63}$" name != null
          )
          agentNames;
        message = "Hermes agent names must be valid upstream profile IDs and cannot be 'default'.";
      }
      {
        assertion = !cfg.gateway.enable || localProfiles != [];
        message = "services.hermes-agent.gateway.enable requires at least one local agent client.";
      }
      {
        assertion = !cfg.dashboard.enable || localProfiles != [];
        message = "services.hermes-agent.dashboard.enable requires at least one local agent client.";
      }
      {
        assertion = !cfg.gateway.enable || !cfg.dashboard.enable || cfg.gateway.port != cfg.dashboard.port;
        message = "Hermes gateway and dashboard ports must differ.";
      }
    ];

    home.packages = [hermesShim];
  };
}
