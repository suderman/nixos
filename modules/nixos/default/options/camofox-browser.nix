{
  config,
  lib,
  perSystem,
  flake,
  ...
}: let
  users = flake.lib.filterUsers config (
    user:
      user.services.camofox-browser.enable
  );

  runFileFor = runDir: profile: kind: "${runDir}/camofox-${profile}-${kind}";
  derivePort = name: base: let
    op = acc: char: lib.mod ((acc * 33) + lib.strings.charToInt char) base;
    chars = lib.strings.stringToCharacters "${toString base}:${name}";
  in
    base + 1 + (builtins.foldl' op 5381 chars);

  deriveServicePort = service: profile: base: derivePort "${service}:${profile}" base;
in {
  system.activationScripts.camofox-browser-keys = let
    inherit (perSystem.self) mkScript derive;
    hex = config.age.secrets.hex.path;

    perUser = user: let
      inherit (user.home) username;
      profiles = lib.unique user.services.camofox-browser.profiles;
      runDir = user.services.camofox-browser.runDir;
      seed = "camofox:${user.home.username}:${config.networking.hostName}";
    in
      lib.concatMapStrings (profile:
        # bash
        ''
          key="$(mktemp)"
          install -dm700 -o ${username} -g users ${runDir}

          derive hex '${seed}:${profile}:api-key' <${hex} >$key
          install -m600 -o ${username} -g users $key ${runFileFor runDir profile "api-key"}

          derive hex '${seed}:${profile}:access-key' <${hex} >$key
          install -m600 -o ${username} -g users $key ${runFileFor runDir profile "access-key"}

          derive hex '${seed}:${profile}:admin-key' <${hex} >$key
          install -m600 -o ${username} -g users $key ${runFileFor runDir profile "admin-key"}
          rm -f $key
        '')
      profiles;

    text = lib.concatMapStrings (user:
      # bash
      ''
        if [[ -f ${hex} ]]; then
          ${perUser user}
        fi
      '')
    users;
    path = [derive];
  in
    lib.mkAfter ''
      # Derive Camofox secrets into each user's run directory
      ${mkScript {inherit text path;}}
    '';

  services.traefik.proxy = builtins.listToAttrs (
    lib.concatMap (
      user: let
        inherit (config.networking) hostName;
        gatewayAgents =
          if user.services.hermes-agent.enable
          then builtins.attrNames (lib.filterAttrs (_: agent: agent.gateway) user.services.hermes-agent.agents)
          else [];
        profiles = lib.unique (user.services.camofox-browser.profiles ++ gatewayAgents);
        cfg = user.services.camofox-browser;
        apiPortFor = profile: deriveServicePort "camofox" profile (cfg.apiBasePort + user.home.portOffset);
        vncPortFor = profile: deriveServicePort "camofox-vnc" profile (cfg.vncBasePort + user.home.portOffset);
      in
        (lib.concatMap (profile: [
            {
              name = "api-${profile}-${cfg.name}";
              value = {
                hostName = "api.${profile}.${cfg.name}.${hostName}";
                url = "http://127.0.0.1:${toString (apiPortFor profile)}";
              };
            }
          ])
          profiles)
        ++ (lib.concatMap (profile:
          lib.optionals cfg.enableVnc [
            {
              name = "${profile}-${cfg.name}";
              value = {
                hostName = "${profile}.${cfg.name}.${hostName}";
                url = "http://127.0.0.1:${toString (vncPortFor profile)}";
              };
            }
          ])
        profiles)
    )
    users
  );
}
