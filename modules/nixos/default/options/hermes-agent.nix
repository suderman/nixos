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
  identityRotation.verificationCommands =
    lib.concatMapStrings (user: let
      inherit (user.lib.hermes-agent) runDir seed;
    in ''
      verify_derived ${lib.escapeShellArg seed} ${lib.escapeShellArg "${runDir}/key"}
    '')
    users;

  # Derive API server key for each user into /run/hermes/{uid}/key
  system.activationScripts.hermes-api-key = let
    inherit (perSystem.self) mkScript derive;
    hex = config.identityRotation.hexPath;
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

  # Proxy the one dashboard and multiplex API declared by each user.
  services.traefik.proxy = builtins.listToAttrs (
    lib.concatMap (
      user: let
        inherit (config.networking) hostName;
        cfg = user.services.hermes-agent;
        inherit (user.lib.hermes-agent) apiPort dashboardPort;
      in
        lib.optionals cfg.dashboard.enable [
          {
            name = cfg.name;
            value = "http://127.0.0.1:${toString dashboardPort}";
          }
        ]
        ++ lib.optionals cfg.gateway.enable [
          {
            name = "api-${cfg.name}";
            value = {
              hostName = "api.${cfg.name}.${hostName}";
              url = "http://127.0.0.1:${toString apiPort}";
            };
          }
        ]
    )
    users
  );
}
