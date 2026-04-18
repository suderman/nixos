{
  config,
  lib,
  pkgs,
  perSystem,
  flake,
  ...
}: let
  # Find all home-manager users with hermes service enabled
  users = flake.lib.filterUsers config (user: user.services.hermes-agent.enable);
in {
  # Derive API server key for each user into /run/hermes/{uid}/api_key
  system.activationScripts.hermes-api-key = let
    inherit (perSystem.self) mkScript derive;
    hex = config.age.secrets.hex.path;
    perUser = user: let
      inherit (user.home) username uid;
      seed = user.services.hermes-agent.host;
      keyFile = "/run/hermes/${toString uid}/key.env";
    in
      # bash
      ''
        if [[ -f ${hex} ]]; then
          key_env="$(mktemp)"
          printf 'API_SERVER_KEY=' >$key_env
          derive hex ${seed} <${hex} >>$key_env
          printf '\n' >>$key_env
          install -dm700 -o ${username} -g users $(dirname ${keyFile})
          install -m600 -o ${username} -g users $key_env ${keyFile}
          rm -f $key_env
        fi
      '';
    text = lib.concatMapStrings perUser users;
    path = [derive];
  in
    lib.mkAfter ''
      # Derive Hermes API server key into each user's run directory
      ${mkScript {inherit text path;}}
    '';

  # Enable reverse proxy for each user dashboard: hermes-jon -> http://127.0.0.1:9119
  services.traefik.proxy = lib.listToAttrs (map (user:
    with user.services.hermes-agent; {
      name = "hermes-${user.home.username}";
      value = "http://127.0.0.1:${toString dashboardPort}";
    })
  users);
}
