{ inputs, config, pkgs, lib, ... }: {

  imports = [ ../.
    ./hardware-configuration.nix 
    inputs.hardware.nixosModules.framework
  ] ++ [
    ../keyd.nix
    ../wayland.nix
    ../gnome.nix
    ../vim.nix
  ];

  # services.sabnzbd.enable = true;
  # services.sabnzbd.user = "me";
  # services.sabnzbd.group = "users";

  # https://search.nixos.org/options?show=services.tandoor-recipes.enable&query=services.tandoor-recipes
  services.tandoor-recipes.enable = true;
  services.tandoor-recipes.port = 8081;

  # https://search.nixos.org/options?show=services.gitea.enable&query=services.gitea
  services.gitea.enable = true;
  services.gitea.database.type = "mysql";

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints.web.address = ":80";
      entryPoints.websecure.address = ":443";
      serversTransport.insecureSkipVerify = true;
      api.insecure = true;
      api.dashboard = true;
      # certificatesResolvers.resolver-dns.acme.dnsChallenge = "true";
      # certificatesResolvers.resolver-dns.acme.dnsChallenge.provider = "cloudflare";
      # certificatesResolvers.resolver-dns.acme.dnsChallenge.delaybeforecheck = "0";
      # certificatesResolvers.resolver-dns.acme.storage = "/data/acme.json";
      # certificatesResolvers.resolver-dns.acme.email = "dns@jons.ca";
    };
    dynamicConfigOptions = {
      http.routers.traefik.entrypoints = "websecure";
      http.routers.traefik.rule = "Host(`traefik.cog`)";
      http.routers.traefik.tls = true;
      # http.routers.traefik.tls.certresolver = "resolver-dns";
      # http.routers.traefik.tls.domains[0].main = "${SELF_DOMAIN}";
      # http.routers.traefik.tls.domains[0].sans = "*.${SELF_DOMAIN}";
      http.routers.traefik.service = "api@internal";
      http.services.traefik.loadbalancer.servers = [{ url = "http://localhost:8080"; }];
      # http.routers.router2.rule = "Host(`ocis.cog`)";
      # http.routers.router2.service = "service2";
      # http.services.service2.loadBalancer.servers = [{ url = "http://localhost:9200"; }];
    };
  };

  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers."whoogle-search" = {
    image = "benbusby/whoogle-search";
    ports = [ "5000:5000" ]; #server locahost : docker localhost
  };

  services.traefik.dynamicConfigOptions.http.routers."whoogle-search" = {
    entrypoints = "websecure";
    rule = "Host(`search.cog`)";
    tls = true;
    service = "whoogle-search";
  };
  services.traefik.dynamicConfigOptions.http.services."whoogle-search" = {
    loadBalancer.servers = [{ url = "http://localhost:5000"; }];
  };

  # services.nginx.enable = true;
  # services.nginx.virtualHosts."search.cog" = {
  #   enableACME = false;
  #   forceSSL = false;
  #   # locations."/".proxyPass = "http://localhost:8082";
  #   locations."/".proxyPass = "http://localhost:5000";
  # };

  networking.extraHosts = ''
    127.0.0.1 traefik.cog search.cog ocis.cog
  '';



  # https://github.com/owncloud/ocis/blob/master/deployments/examples/ocis_traefik/docker-compose.yml
  virtualisation.oci-containers.containers."owncloud-ocis" = {
    image = "owncloud/ocis:2";
    entrypoint = "/bin/sh";
    cmd = [ "-c" "ocis init || true; ocis server" ];
    # extraOptions = [ "--pod=ocis" ];
    environment = {
      OCIS_URL = "https://ocis.cog";
      OCIS_LOG_LEVEL = "debug";
      PROXY_TLS = "false"; 
      OCIS_INSECURE = "false";
      GRAPH_LDAP_INSECURE = "true"; # https://github.com/owncloud/ocis/issues/3812
      PROXY_ENABLE_BASIC_AUTH = "true";
      # IDP_SIGNING_PRIVATE_KEY_FILES = "/etc/ocis/idp-private-key.pem";
      # IDP_ENCRYPTION_SECRET_FILE = "/etc/ocis/idp-encryption.key";
      IDM_ADMIN_PASSWORD = "secret"; # this overrides the admin password from the configuration file
      IDM_CREATE_DEMO_USERS = "false";
      # NOTIFICATIONS_SMTP_HOST: ${SELF_SMTP_HOST}
      # NOTIFICATIONS_SMTP_PORT: ${SELF_SMTP_PORT}
      # NOTIFICATIONS_SMTP_SENDER: ${SELF_SMTP_NAME}
      # NOTIFICATIONS_SMTP_PASSWORD: ${SELF_SMTP_PASSWORD}
    };
    ports = [ "9200:9200" ]; #server locahost : docker localhost
    volumes = [
      "my_config:/etc/ocis"
      "my_data:/var/lib/ocis"
    ];
  };

  services.traefik.dynamicConfigOptions.http.routers."ocis" = {
    entrypoints = "websecure";
    rule = "Host(`ocis.cog`)";
    tls = true;
    service = "ocis";
  };
  services.traefik.dynamicConfigOptions.http.services."ocis" = {
    loadBalancer.servers = [{ url = "http://localhost:9200"; }];
  };

  # systemd.services.create-ocis-pod = with config.virtualisation.oci-containers; {
  #   serviceConfig.Type = "oneshot";
  #   wantedBy = [ "${backend}-ocis.service" ];
  #   script = ''
  #     ${pkgs.podman}/bin/podman pod exists elk || \
  #       ${pkgs.podman}/bin/podman pod create -n ocis -p '127.0.0.1:9200:9200'
  #   '';
  # };


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.fprintd.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable sound.
  sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Packages
  environment.systemPackages = with pkgs; [];

  # Docker
  virtualisation.docker.enable = true;

  # Other
  # programs.nix-ld.enable = true;

}
