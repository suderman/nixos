# Traefik

Custom CA certificates are automatically generated with OpenSSL for each
internal host name discovered in the Traefik configuration. External host names
will get certificates from Let's Encrypt using DNS validation against
CloudFlare's API. 

Private host names have an IP whitelist middleware to filter out any publicly
routable IP addresses, and their private IP will be added to Blocky's custom
DNS mapping. Public host names will get their public IP address added as a DNS
record to CloudFlare.

Host names that do not end with the current system's name will be considered
external and assumed public by default.

## Examples

### Route private service to private network

```nix
{
  modules.traefik.routers.foo = "http://bar.hub:80";
}
```

...becomes...  

```nix
{
  services.traefik.dynamicConfigOptions.http = {
    routers.foo = {
      rule = "Host(`foo.lux`)";
      entrypoints = "websecure";
      middlewares = [ "foo" "local" ];
      service = "foo";
      tls = true;
    };
    middlewares.foo = {
      headers.customRequestHeaders.Host = "bar.hub";
    };
    services.foo = {
      loadBalancer.servers = [{ url = "http://bar.hub:80"; }];
    };
  };
}
```

### Route private service to public internet

```nix
{
  modules.traefik.routers."foo.com" = "http://baz.eve:80";
}
```
...becomes...  

```nix
{
  services.traefik.dynamicConfigOptions.http = {
    routers."foo.com" = {
      rule = "Host(`foo.com`,`PUBLIC`)";
      entrypoints = "websecure";
      middlewares = [ "foo.com" ];
      service = "foo.com";
      tls = {
        certresolver = "resolver-dns"; 
        domains = [{
          main = "foo.com";
          sans = "*.foo.com";
        }];
      };
    };
    middlewares."foo.com" = {
      headers.customRequestHeaders.Host = "baz.eve";
    };
    services."foo.com" = {
      loadBalancer.servers = [{ url = "https://baz.eve:443"; }];
    };
  };
}
```

### Add extra Traefik options through "http" attribute in module

```nix
{
  modules.traefik = { 
    routers.isy = "http://${this.networks.home.isy}:80";
    http = {
      middlewares.isy.headers.customRequestHeaders.authorization = "Basic {{ env `ISY_BASIC_AUTH` }}";
    };
  };
}
```

### Add Traefik labels to a Docker container

```nix
{
  virtualisation.oci-containers.containers.lunasea = {
    image = "ghcr.io/jagandeepbrar/lunasea:stable";
    extraOptions = config.modules.traefik.labels "lunasea";
  };
}
```

...becomes...  

```nix
{
  virtualisation.oci-containers.containers.lunasea = {
    image = "ghcr.io/jagandeepbrar/lunasea:stable";
    extraOptions = [ 
      "--label=traefik.enable=true" 
      "--label=traefik.http.routers.lunasea.entrypoints=websecure"
      "--label=traefik.http.routers.lunasea.rule=Host(`lunasea.lux`)" 
      "--label=traefik.http.routers.lunasea.tls=true" 
      "--label=traefik.http.routers.lunasea.middlewares=local@file" 
    ];
  };
}
```

### Public domain example

```nix
{
  virtualisation.oci-containers.containers.lunasea = {
    image = "ghcr.io/jagandeepbrar/lunasea:stable";
    extraOptions = config.modules.traefik.labels "example.com";
  };
}
```

...becomes...  

```nix
{
  virtualisation.oci-containers.containers.lunasea = {
    image = "ghcr.io/jagandeepbrar/lunasea:stable";
    extraOptions = [ 
      "--label=traefik.enable=true" 
      "--label=traefik.http.routers.example_com.entrypoints=websecure"
      "--label=traefik.http.routers.example_com.rule=Host(`example.com`,`PUBLIC`)" 
      "--label=traefik.http.routers.example_com.tls.certresolver=resolver-dns"
      "--label=traefik.http.routers.example_com.tls.domains[0].main=example.com"
      "--label=traefik.http.routers.example_com.tls.domains[1].sans=*.example.com"
    ];
  };
}
```
