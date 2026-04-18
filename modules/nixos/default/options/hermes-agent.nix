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

  inherit (lib) concatMap listToAttrs mapAttrsToList optionalString;
  inherit (lib.strings) charToInt stringToCharacters;

  deriveProfilePort = base: profile: salt: let
    maxOffset = 65535 - base - 1;
    # Keep profile ports stable: derive from only salt + profile name so adding
    # or removing sibling profiles cannot renumber existing ports.
    offset =
      if maxOffset <= 0
      then throw "services.hermes-agent.apiPort must leave room for derived profile ports"
      else builtins.foldl' (
        acc: char: lib.mod ((acc * 33) + charToInt char) maxOffset
      ) 5381 (stringToCharacters "${salt}:${profile}");
  in
    base + 1 + offset;

  userProxyEntries = user: let
    inherit (user.home) username;
    cfg = user.services.hermes-agent;
    proxyUrl = profile: let
      port =
        if profile == "default"
        then cfg.apiPort
        else deriveProfilePort cfg.apiPort profile "api";
    in "http://127.0.0.1:${toString port}";
  in
    mapAttrsToList (profile: hostName: {
      name = "hermes-${username}${optionalString (profile != "default") "-${profile}"}";
      value = {
        inherit hostName;
        url = proxyUrl profile;
      };
    }) cfg.proxy;
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

  # Explicitly proxy only the Hermes profiles listed in each user's home-manager
  # config. `default` targets the root Hermes home; other keys target
  # ~/.hermes/profiles/<name> using the same stable name-based port derivation as
  # gateway-sync.py.
  services.traefik.proxy = listToAttrs (concatMap userProxyEntries users);

}
