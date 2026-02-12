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
  system.activationScripts.openclawGatewayToken.text = let
    inherit (perSystem.self) mkScript;
    hex = config.age.secrets.hex.path;
    perUser = user: let
      inherit (user.home) username uid;
      inherit (user.programs.openclaw) seed;
      runDir = "/run/user/${toString uid}/openclaw";
    in
      # bash
      ''
        if [[ -f ${hex} ]]; then
          install -d -m 775 ${runDir}
          cat ${hex} |
          derive hex ${seed} >${runDir}/gateway
          chown -R ${username}:users /run/openclaw
        fi
      '';
    text = lib.concatMapStrings perUser users;
    path = [perSystem.self.derive];
  in
    lib.mkAfter "${mkScript {inherit text path;}}";

  # Create the reproxy for each user with enabled the openclaw service
  # Enable reverse proxy { "openclaw-jon" = "http://cog:11000"; }
  services.traefik.proxy = lib.listToAttrs (map (user:
    with user.services.openclaw; {
      inherit name;
      value = "http://127.0.0.1:${toString port}";
    })
  gatewayUsers);
}
