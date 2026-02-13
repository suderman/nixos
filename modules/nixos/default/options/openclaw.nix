{
  config,
  lib,
  perSystem,
  flake,
  ...
}: let
  # find all home-manager users with openclaw program enabled
  users = flake.lib.filterUsers config (user: user.programs.openclaw.enable);

  # find all home-manager users with openclaw service enabled
  gatewayUsers = flake.lib.filterUsers config (user: user.services.openclaw.enable);
in {
  # Derive the gateway token to runDir
  system.activationScripts.users.text = let
    inherit (perSystem.self) mkScript;
    hex = config.age.secrets.hex.path;
    perUser = user: let
      inherit (user.home) username;
      inherit (user.lib.openclaw) runDir seed;
    in
      # bash
      ''
        if [[ -f ${hex} ]]; then
          token="$(mktemp)"
          derive hex ${seed} <${hex} >$token
          install -dm700 -o ${username} -g users ${runDir}
          install -m600 -o ${username} -g users $token ${runDir}/gateway
          rm -f $token
        fi
      '';
    text = lib.concatMapStrings perUser users;
    path = [perSystem.self.derive];
  in
    lib.mkAfter ''
      # Derive the OpenClaw gateway token into each user's run directory
      ${mkScript {inherit text path;}}
    '';

  # Enable reverse proxy for each user { "openclaw-jon" = "http://127.0.0.1:11000"; }
  services.traefik.proxy = lib.listToAttrs (map (user:
    with user.services.openclaw; {
      inherit name;
      value = "http://127.0.0.1:${toString port}";
    })
  gatewayUsers);
}
