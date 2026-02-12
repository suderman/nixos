{
  config,
  flake,
  ...
}: {
  imports = flake.lib.ls ./.;

  # openclaw devices list
  # openclaw devices approve <requestId>
  # openclaw devices reject <requestId>
  config.lib.openclaw = {
    # The gateway token is written to the user's run directory
    runDir = "/run/user/${toString config.home.uid}/openclaw";

    # Seed is used to derive gateway token and we use the openclaw host
    # First try to use the program's host, unless it's set to 127.0.0.1
    # in which case, fall back on the service's host instead
    seed =
      if config.programs.openclaw.host != "127.0.0.1"
      then config.programs.openclaw.host
      else config.services.openclaw.host;

    # Port the openclaw gateway is available on.
    # If the program's host is 127.0.0.1, we can assume the gateway is local.
    # Otherwise, we'll assume it's behind a reverse proxy server on 443
    port =
      if config.programs.openclaw.host == "127.0.0.1"
      then 11000 + config.home.portOffset
      else 443;
  };
}
