# services.openssh.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.services.openssh;

in {

  config = lib.mkIf cfg.enable {

    services.openssh = {

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

    # Passwordless sudo when SSH'ing with keys
    security.pam.enableSSHAgentAuth = true;

  };

}
