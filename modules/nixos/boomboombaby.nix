{
  config,
  flake,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.boomboombaby;
  # https://www.cloudflare.com/ips/ (checked 2026-11-01).
  cloudflareIPv4 = [
    "173.245.48.0/20"
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "141.101.64.0/18"
    "108.162.192.0/18"
    "190.93.240.0/20"
    "188.114.96.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
    "162.158.0.0/15"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "172.64.0.0/13"
    "131.0.72.0/22"
  ];
  cloudflareIPv6 = [
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
  ];
in {
  imports = [flake.inputs.bbbscores.nixosModules.default];

  options.services.boomboombaby.enable = lib.mkEnableOption "Boom Boom Baby websites and scores behind Cloudflare";

  config = lib.mkIf cfg.enable {
    services.bbbscores = {
      enable = true;
      allowedOrigins = [
        "https://game1.boomboombaby.ca"
        "https://game2.boomboombaby.ca"
        "https://boomboombaby.ca"
        "https://*.itch.zone"
      ];
      clientIpHeader = "x-real-ip";
    };

    services.caddy = {
      enable = true;
      globalConfig = ''
        servers {
          trusted_proxies static ${lib.concatStringsSep " " (cloudflareIPv4 ++ cloudflareIPv6)}
          client_ip_headers CF-Connecting-IP
          trusted_proxies_strict
        }
      '';
      extraConfig = ''
        (cloudflare-tls) {
          tls {
            issuer acme {
              disable_tlsalpn_challenge
            }
          }
          encode zstd gzip
        }
        (website) {
          import cloudflare-tls
          root * /srv/www/{args[0]}
          header Cache-Control "public, max-age=60, must-revalidate"
          @html path / /index.html
          header @html >Cache-Control "no-cache"
          file_server
        }
      '';
      virtualHosts = {
        "boomboombaby.ca".extraConfig = "import website boomboombaby";
        "game1.boomboombaby.ca".extraConfig = "import website game1";
        "game2.boomboombaby.ca".extraConfig = "import website game2";
        "www.boomboombaby.ca".extraConfig = ''
          import cloudflare-tls
          redir https://boomboombaby.ca{uri} permanent
        '';
        # Let Node serve scores.json with its cache policy; keep its state directory private.
        "scores.boomboombaby.ca".extraConfig = ''
          import cloudflare-tls
          reverse_proxy 127.0.0.1:${toString config.services.bbbscores.port} {
            # Replace any visitor-supplied header with Caddy's trusted client IP.
            header_up X-Real-IP {client_ip}
          }
        '';
      };
    };

    networking.firewall.extraCommands =
      lib.concatMapStringsSep "\n" (range: ''
        iptables -w -A nixos-fw -s ${range} -p tcp -m multiport --dports 80,443 -j nixos-fw-accept
      '')
      cloudflareIPv4
      + "\n"
      + lib.concatMapStringsSep "\n" (range: ''
        ip6tables -w -A nixos-fw -s ${range} -p tcp -m multiport --dports 80,443 -j nixos-fw-accept
      '')
      cloudflareIPv6;

    persist.storage.directories = [
      {
        directory = "/var/lib/bbbscores";
        user = "bbbscores";
        group = "bbbscores";
        mode = "0700";
      }
      {
        directory = "/var/lib/caddy";
        user = "caddy";
        group = "caddy";
        mode = "0700";
      }
      {
        directory = "/srv/www";
        user = "jon";
        group = "users";
        mode = "0755";
      }
    ];
    systemd.services.caddy.serviceConfig.StateDirectoryMode = "0700";
    # A first switch must mount persistent content before tmpfiles seeds it.
    systemd.services.systemd-tmpfiles-resetup.unitConfig.RequiresMountsFor = ["/srv/www"];

    # Jon deploys from kit over ordinary tailnet SSH using each repo's rsync script.
    tmpfiles.directories = map (site: {
      target = "/srv/www/${site}";
      user = "jon";
      group = "users";
      mode = "0755";
    }) ["boomboombaby" "game1" "game2"];
    # C copies only when absent. Rebuilds must not overwrite a deployed index.html.
    systemd.tmpfiles.rules = map (site: let
      placeholder = pkgs.writeText "${site}-placeholder.html" ''
        <!doctype html><html lang="en"><meta charset="utf-8"><title>Boom Boom Baby</title><h1>Boom Boom Baby</h1><p>${site} is coming soon.</p></html>
      '';
    in "C /srv/www/${site}/index.html 0644 jon users - ${placeholder}") ["boomboombaby" "game1" "game2"];
  };
}
