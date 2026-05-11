{
  config,
  lib,
  perSystem,
  flake,
  ...
}: let
  # Find all home-manager users with hermes service enabled
  users = flake.lib.filterUsers config (user: user.services.hermes-agent.enable);
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
}
