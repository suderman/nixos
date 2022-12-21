{ config, lib, pkgs, ... }:

let
  cfg = config.services.openssh;
  # prefix = "/persist";
  prefix = "";

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

    hostKeys = [{
      path = "${prefix}/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    } {
      path = "${prefix}/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }];

  };

  # Passwordless sudo when SSH'ing with keys
  security.pam.enableSSHAgentAuth = lib.mkIf cfg.enable true ;

  # environment.etc = {
  #   "ssh/ssh_host_rsa_key".source = "${prefix}/etc/ssh/ssh_host_rsa_key";
  #   "ssh/ssh_host_rsa_key.pub".source = "${prefix}/etc/ssh/ssh_host_rsa_key.pub";
  #   "ssh/ssh_host_ed25519_key".source = "${prefix}/etc/ssh/ssh_host_ed25519_key";
  #   "ssh/ssh_host_ed25519_key.pub".source = "${prefix}/etc/ssh/ssh_host_ed25519_key.pub";
  # };
  

}
