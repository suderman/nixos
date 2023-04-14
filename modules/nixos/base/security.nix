{ config, lib, ... }: 

let

  cfg = config.modules.base;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    security = {

      # Does sudo need a password?
      sudo.wheelNeedsPassword = true;

      # If so, how long before asking again?
      sudo.extraConfig = lib.mkAfter ''
        Defaults timestamp_timeout=60
        Defaults lecture=never
      '';

      # Increase open file limit for sudoers
      pam.loginLimits = [
        { domain = "@wheel"; item = "nofile"; type = "soft"; value = "524288"; }
        { domain = "@wheel"; item = "nofile"; type = "hard"; value = "1048576"; }
      ];

      # Passwordless sudo when SSH'ing with keys
      pam.enableSSHAgentAuth = true;

    };

    services.openssh = {
      enable = true;

      # Harden
      passwordAuthentication = false;
      permitRootLogin = "yes";

      # Automatically remove stale sockets
      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      # Allow forwarding ports to everywhere
      gatewayPorts = "clientspecified";

    };

  };

}
