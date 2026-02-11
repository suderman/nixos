{
  config,
  lib,
  perSystem,
  flake,
  ...
}: let
  inherit (flake.lib) anyUser filterUsers;

  # True if at least one user has enabled programs.openclaw
  enableToken = anyUser config (u: u.programs.openclaw.enable);

  # True if at least one user has enabled services.openclaw
  enableProxy = anyUser config (u: u.services.openclaw.enable);

  cfg = let
    programUsers =
      if enableToken
      then (filterUsers config (user: user.programs.openclaw.enable))
      else [{}];
    programUser = builtins.head programUsers;
    serviceUsers =
      if enableProxy
      then (filterUsers config (user: user.services.openclaw.enable))
      else [{}];
    serviceUser = builtins.head serviceUsers;
  in {
    host = programUser.programs.openclaw.host or null;
    name = serviceUser.services.openclaw.name or null;
    port = serviceUser.services.openclaw.port or null;
    # inherit (programUser.programs.openclaw) host; # seed for gateway token
    # inherit (serviceUser.services.openclaw) name port;
  };
in {
  # Derive the gateway token to /run/openclaw/token
  config.system = lib.mkIf enableToken {
    activationScripts.openclawGatewayToken.text = let
      inherit (perSystem.self) mkScript;
      hex = config.age.secrets.hex.path;
      text =
        # bash
        ''
          if [[ -f ${hex} ]]; then
            install -d -m 775 /run/openclaw
            cat ${hex} |
            derive hex ${cfg.host} >/run/openclaw/gateway
            chown -R :users /run/openclaw
          fi
        '';
      path = [perSystem.self.derive];
    in
      lib.mkAfter "${mkScript {inherit text path;}}";
  };

  # Create the traefik proxy if one user has enabled the openclaw service
  config.services = lib.mkIf enableProxy {
    traefik.proxy."${cfg.name}" = cfg.port;
  };
}
