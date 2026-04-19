{
  config,
  lib,
  perSystem,
  flake,
  ...
}: let
  # Find all home-manager users with hermes service enabled
  users = flake.lib.filterUsers config (user: user.services.hermes-agent.enable);

  inherit (lib) concatMap listToAttrs mapAttrsToList;
  inherit (lib.strings) charToInt stringToCharacters;

  deriveAgentPort = base: agent: salt: let
    maxOffset = 65535 - base - 1;
    # Keep agent ports stable: derive from only salt + agent name so adding or
    # removing sibling agents cannot renumber existing ports.
    offset =
      if maxOffset <= 0
      then throw "services.hermes-agent.apiPort must leave room for derived agent ports"
      else
        builtins.foldl' (
          acc: char: lib.mod ((acc * 33) + charToInt char) maxOffset
        )
        5381 (stringToCharacters "${salt}:${agent}");
  in
    base + 1 + offset;

  userProxyEntries = user: let
    inherit (user.home) username;
    cfg = user.services.hermes-agent;
    proxyUrl = agent: let
      port = deriveAgentPort cfg.apiPort agent "api";
    in "http://127.0.0.1:${toString port}";
  in
    builtins.filter (entry: entry != null) (mapAttrsToList (agent: agentCfg:
      if agentCfg.proxy == null
      then null
      else {
        name = "hermes-${username}-${agent}";
        value = {
          hostName = agentCfg.proxy;
          url = proxyUrl agent;
        };
      })
    cfg.agents);
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

  # Explicitly proxy only the Hermes agents declared in each user's
  # home-manager config using the same stable name-based port derivation as the
  # home-manager gateway module.
  services.traefik.proxy = listToAttrs (concatMap userProxyEntries users);
}
