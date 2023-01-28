{ config, lib, pkgs, ... }:

let
  cfg = config.services.openssh;

in {

  # services.openssh.enable = true;
  services.openssh = lib.mkIf cfg.enable {

    # Harden
    passwordAuthentication = false;
    permitRootLogin = "no";

    # Automatically remove stale sockets
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';

    # Allow forwarding ports to everywhere
    gatewayPorts = "clientspecified";

  };

  # Passwordless sudo when SSH'ing with keys
  security.pam.enableSSHAgentAuth = lib.mkIf cfg.enable true ;

}
