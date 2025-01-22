{ config, lib, pkgs, this, ... }: let

  inherit (lib) filterAttrs mkAfter;
  inherit (this.lib) mkAttrs;

in {

  security = {

    # Does sudo need a password?
    sudo.wheelNeedsPassword = true;

    # If so, how long before asking again?
    sudo.extraConfig = mkAfter ''
      Defaults timestamp_timeout=60
      Defaults lecture=never
    '';

    # Increase open file limit for sudoers
    pam.loginLimits = [
      { domain = "@wheel"; item = "nofile"; type = "soft"; value = "524288"; }
      { domain = "@wheel"; item = "nofile"; type = "hard"; value = "1048576"; }
    ]; 

    # Passwordless sudo when SSH'ing with keys
    pam.sshAgentAuth = {
      enable = true;
      # https://github.com/NixOS/nixpkgs/issues/31611
      authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    };

    # Add CA certificate to system's trusted root store
    pki.certificateFiles = [ this.ca ];

  };

  # Set environment variables for every service
  environment.sessionVariables = {

    # # Convince python to trust CA certificate
    # REQUESTS_CA_BUNDLE = this.ca;
    # PIP_CERT = this.ca;

    # Convince node to trust CA certificate
    NODE_EXTRA_CA_CERTS = this.ca;

    # # Convince everyone else to trust CA certificate
    # SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";

  };

  # Enable passwordless ssh access
  services.openssh = {
    enable = true;

    # Harden
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "yes";

    # Automatically remove stale sockets
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';

    # Allow forwarding ports to everywhere
    settings.GatewayPorts = "clientspecified";

  };

  # Start ssh agent and add all configurations as known hosts
  programs.ssh = let 
    keys = filterAttrs (k: v: k != "all") config.secrets.keys.systems;
  in {
    knownHosts = mkAttrs keys (host: {
      publicKey = keys.${host};
      extraHostNames = [ "${host}.${this.domain}" ];
    });
    startAgent = true;
  };

}
