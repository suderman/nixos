{
  lib,
  flake,
  ...
}: let
  inherit (builtins) readFile;
  inherit (lib) genAttrs mkAfter;
  inherit (flake.lib) ls;
  inherit (flake.networking) ca domainName;

  # Convert my computers to trust my custom ca
  caBundle = "/etc/ssl/certs/ca-bundle.crt";
  trustEnv = {
    # Generic OpenSSL-ish clients
    SSL_CERT_FILE = caBundle;

    # Python requests / httpx-adjacent tooling
    REQUESTS_CA_BUNDLE = caBundle;

    # curl/libcurl/git ecosystem fallback
    CURL_CA_BUNDLE = caBundle;

    # nix fetchers/substituters/flakes
    NIX_SSL_CERT_FILE = caBundle;

    # Node wants the extra CA, not necessarily the whole bundle.
    NODE_EXTRA_CA_CERTS = ca;
  };
in {
  security = {
    # Does sudo need a password?
    sudo.wheelNeedsPassword = true;

    # First line solves remote deploys asking sudo password more than once
    sudo.extraConfig = mkAfter ''
      Defaults timestamp_type=global
      Defaults timestamp_timeout=60
      Defaults lecture=never
    '';

    # Increase the open file limit (512x soft, 256x hard) over the defaults
    pam.loginLimits = let
      soft = {
        type = "soft";
        item = "nofile";
        value = "524288";
      };
      hard = {
        type = "hard";
        item = "nofile";
        value = "1048576";
      };
      sudo = {domain = "@wheel";};
      root = {domain = "root";};
    in [(sudo // soft) (sudo // hard) (root // soft) (root // hard)];

    # https://github.com/NixOS/nixpkgs/issues/31611
    pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
    };

    pam.services.login.sshAgentAuth = true;

    # Add CA certificate to system's trusted root store
    pki.certificateFiles = [ca];
  };

  # Interactive shells, desktop sessions, CLI tools, agents launched from user env.
  environment.sessionVariables = trustEnv;

  # System services. Do not assume sessionVariables reach these.
  systemd.globalEnvironment = trustEnv;

  # Enable passwordless ssh access
  services.openssh = {
    enable = true;

    # Allow root over ssh, but disable via password
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = false;

    # Automatically remove stale sockets
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';

    # Allow forwarding ports to everywhere
    settings.GatewayPorts = "clientspecified";
  };

  # Add all configurations as known hosts
  programs.ssh = let
    hostNames = ls {
      path = flake + /hosts;
      dirsWith = ["ssh_host_ed25519_key.pub"];
      asPath = false;
    };
  in {
    knownHosts = genAttrs hostNames (hostName: {
      publicKey = readFile (flake + /hosts/${hostName}/ssh_host_ed25519_key.pub);
      extraHostNames = ["${hostName}.${domainName}"];
    });
  };

  # Custom CA private key
  # openssl genrsa -out ca.key 4096
  age.secrets.ca.rekeyFile = flake + /zones/ca.age;

  # Add terminfo files
  environment.enableAllTerminfo = true;
}
