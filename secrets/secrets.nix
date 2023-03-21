with (import ./keys); {

  # Long secret with characters constrained to alphabet and digits
  # > tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' ; echo
  "files/alphanumeric-secret.age".publicKeys = all;

  # Basic Auth for traefik
  # > nix shell nixpkgs#apacheHttpd -c htpasswd -nb USERNAME PASSWORD
  # ---------------------------------------------------------------------------
  # USERNAME:$apr1$9GXtleUd$Bc0cNYaR42mIUvys6zJfB/
  # ---------------------------------------------------------------------------
  "files/basic-auth.age".publicKeys = all;

  # CloudFlare DNS API Token used by Traefik & Let's Encrypt
  # ---------------------------------------------------------------------------
  # CF_DNS_API_TOKEN=xxxxxx
  # ---------------------------------------------------------------------------
  "files/cloudflare-env.age".publicKeys = all;

  # Encrypted password for NixOS user account
  # > mkpasswd -m sha-512 mySecr3tpa$$w0rd!
  "files/password.age".publicKeys = all;

  # .env for tailscale-cloudflare-dnssync
  # ---------------------------------------------------------------------------
  # cf-key=<https://dash.cloudflare.com/profile/api-tokens>
  # cf-domain=example.com
  # ts-key=<https://login.tailscale.com/admin/settings/keys>
  # ts-tailnet=example.github
  # ---------------------------------------------------------------------------
  "files/tailscale-cloudflare.age".publicKeys = all;

  # Testing
  "files/foo.age".publicKeys = all;
  "files/bar.age".publicKeys = all;

  "files/tandoor-env.age".publicKeys = all;

  "files/smtp-env.age".publicKeys = all;

}
