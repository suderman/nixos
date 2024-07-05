{ config, lib, pkgs, ... }: { 

  # Experiments
  systemd.user.services.foobar = {
    description = "Foobar NixOS";
    after = [ "graphical-session.target" ];
    requires = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    environment = {
      FOO = "bar";
    };
    path = with pkgs; [ coreutils ];
    script = ''
      touch /tmp/foobar.txt
      date >> /tmp/foobar.txt
    '';
  };

  # services.prometheus.enable = true;
  # services.grafana.enable = true;

  # services.ocis = {
  #   enable = true;
  #   url = "http://127.0.0.1:9200";
  #   environment = with config.services.ocis; {
  #     OCIS_INSECURE = "true";
  #     # OCIS_URL = "https://ocis.cog";
  #     # PROXY_HTTP_ADDR = "${address}:${toString port}";
  #     # PROXY_TLS = "false";
  #   };
  # };
  #
  # file."${config.services.ocis.stateDir}" = { 
  #   type = "dir"; 
  #   mode = 775; 
  #   user = config.services.ocis.user; 
  #   group = config.services.ocis.group; 
  # };

  file."/etc/foo" = { type = "dir"; };
  file."/etc/foo/bar" = { text = "Hello world!"; mode = 665; user = 913; };
  file."/etc/foo/symlink" = { type = "link"; source = /etc/foo/bar; };
  file."/etc/foo/resolv" = { type = "file"; mode = 775; user = "jon"; group = "users"; source = /etc/resolv.conf; };
  file."/etc/foo/srv" = { type = "dir"; source = /srv; };

  # services.gitea.enable = true;
  # services.tandoor-recipes.enable = false;
  # services.rsshub.enable = true;
  # services.jellyfin.enable = false;
  # modules.home-assistant.enable = true;
  # modules.unifi = with this.network.dns; {
  #   enable = true;
  #   gateway = home.logos;
  # };
  # services.freshrss.enable = true;
  # services.whoogle = { enable = true; name = "g"; };
  # services.tiddlywiki.enable = true;
  # modules.nextcloud.enable = false;
  # modules.ocis = { enable = true; dataDir = "/tmp/ocis"; };
  # modules.silverbullet.enable = true;
  # services.bluebubbles.enable = true;
  # services.traefik = { 
  #   proxy.isy = "http://${this.networks.home.isy}:80";
  #   dynamicConfigOptions.http = {
  #     middlewares.isy.headers.customRequestHeaders.authorization = "Basic {{ env `ISY_BASIC_AUTH` }}";
  #   };
  #   proxy."foo.bar" = "https://whoami.cog";
  # };


  # # services.wordpress.webserver = "nginx";
  # services.wordpress.sites."wpcog" = {
  #   database.name = "wpcog";
  #   # virtualHost.documentRoot = "/var/lib/wordpress/wpcog/root";
  #   # virtualHost.serverAliases = [
  #   #   "wp.cog.suderman.org"
  #   #   "wp.cog.suderman.org:8080"
  #   #   "example.org"
  #   # ];
  #   # virtualHost.listen = [{
  #   #   ip = "*";
  #   #   port = 8080;
  #   # }];
  # };
  # services.httpd.virtualHosts."wpcog" = {
  #   documentRoot = lib.mkOverride 40 "/var/lib/wordpress/wpcog/root";
  #   serverAliases = [
  #     "wp.cog.suderman.org"
  #     "wp.cog.suderman.org:8080"
  #     "example.org"
  #   ];
  #   listen = [{
  #     ip = "*";
  #     port = 8080;
  #   }];
  # };


}
