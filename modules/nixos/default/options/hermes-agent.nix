{
  config,
  lib,
  perSystem,
  flake,
  ...
}: let
  # Find all home-manager users with hermes service enabled
  users = flake.lib.filterUsers config (user: user.services.hermes-agent.enable);
  matrixUsers = flake.lib.filterUsers config (
    user: user.services.hermes-agent.enable && user.services.hermes-agent.matrix.enable
  );
  matrixLocalUserNames = lib.unique (lib.concatMap (user: builtins.attrNames user.services.hermes-agent.agents) matrixUsers);
in {
  # Derive API server key for each user into /run/hermes/{uid}/key
  system.activationScripts.hermes-api-key = let
    inherit (perSystem.self) mkScript derive;
    hex = config.age.secrets.hex.path;
    perUser = user: let
      inherit (user.home) username;
      inherit (user.lib.hermes-agent) runDir seed;
    in
      # bash
      ''
        if [[ -f ${hex} ]]; then
          key="$(mktemp)"
          derive hex ${seed} <${hex} >$key
          install -dm700 -o ${username} -g users ${runDir}
          install -m600 -o ${username} -g users $key ${runDir}/key
          rm -f $key
        fi
      '';
    text = lib.concatMapStrings perUser users;
    path = [derive];
  in
    lib.mkAfter ''
      # Derive Hermes API server key into each user's run directory
      ${mkScript {inherit text path;}}
    '';

  # Derive Matrix passwords for each enabled Hermes user and agent.
  system.activationScripts.hermes-matrix-passwords = let
    inherit (perSystem.self) mkScript derive;
    hex = config.age.secrets.hex.path;
    perUser = user: let
      inherit (user.home) username;
      inherit (user.lib.hermes-agent) runDir;
      matrixAgents = builtins.attrNames user.services.hermes-agent.agents;
    in
      # bash
      ''
        if [[ -f ${hex} ]]; then
          ${lib.optionalString user.services.hermes-agent.matrix.enable ''
            install -dm700 -o ${username} -g users "${runDir}/matrix"

            ${lib.concatMapStrings (agent: let
              serverName = user.services.hermes-agent.matrix.serverName;
              seed = "matrix-synapse:${serverName}:${agent}:password";
            in ''
              password="$(mktemp)"
              derive hex ${lib.escapeShellArg seed} <${hex} >"$password"
              install -m600 -o ${username} -g users "$password" "${runDir}/matrix/${agent}.password"
              rm -f "$password"
            '') matrixAgents}
          ''}

          ${lib.optionalString (!user.services.hermes-agent.matrix.enable) ''
            if [[ -d "${runDir}/matrix" ]]; then
              shopt -s nullglob
              for password in "${runDir}/matrix"/*.password; do
                rm -f "$password"
              done
              rmdir "${runDir}/matrix" 2>/dev/null || true
            fi
          ''}
        fi
      '';
    text = lib.concatMapStrings perUser users;
    path = [derive];
  in
    lib.mkAfter ''
      # Derive Hermes Matrix passwords into each user's run directory
      ${mkScript {inherit text path;}}
    '';

  # Proxy Hermes dashboards and APIs declared by each user
  services.traefik.proxy = builtins.listToAttrs (
    lib.concatMap (
      user: let
        inherit (config.networking) hostName;
        inherit (user.lib.hermes-agent) agentNames apiPortFor dashboardPortFor gatewayAgents;
      in
        (lib.concatMap (name: [
          {
            inherit name;
            value = "http://127.0.0.1:${toString (dashboardPortFor name)}";
          }
        ])
        agentNames)
        ++ (lib.concatMap (name: [
          {
            name = "api-${name}";
            value = {
              hostName = "api.${name}.${hostName}";
              url = "http://127.0.0.1:${toString (apiPortFor name)}";
            };
          }
        ])
        gatewayAgents)
    )
    users
  );

  services.matrix-synapse.localUsers = lib.mkIf config.services.matrix-synapse.enable (
    builtins.listToAttrs (map (name: {
      inherit name;
      value = {};
    }) matrixLocalUserNames)
  );
}
