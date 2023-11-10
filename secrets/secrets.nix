with (import ./keys); {

  # Password hash for NixOS user account
  # > mkpasswd -m sha-512 mySecr3tpa$$w0rd!
  "files/password-hash.age".publicKeys = all;

  # Plain-text password (typically used in web services)
  "files/password.age".publicKeys = all;

  # Traefik Environment Variables
  # ---------------------------------------------------------------------------
  # CloudFlare DNS API Token 
  # > https://dash.cloudflare.com/profile/api-tokens
  # ---------------------------------------------------------------------------
  # CF_DNS_API_TOKEN=xxxxxx
  # ---------------------------------------------------------------------------
  # Encoded ISY authentication header
  # > echo -n $ISY_USERNAME:$ISY_PASSWORD | base64
  # ---------------------------------------------------------------------------
  # ISY_BASIC_AUTH=xxxxxx
  # ---------------------------------------------------------------------------
  "files/traefik-env.age".publicKeys = all;

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

  # SMTP Email Server + Secret Key
  # ---------------------------------------------------------------------------
  # EMAIL_HOST=smtp.example.com
  # EMAIL_PORT=587
  # EMAIL_HOST_USER=user@example.com
  # EMAIL_HOST_PASSWORD=xxxxxxxxxxxx
  # EMAIL_USE_TLS=1
  # EMAIL_USE_SSL=0
  # SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  # ---------------------------------------------------------------------------
  "files/smtp-env.age".publicKeys = all;

  # Long secret with characters constrained to alphabet and digits
  # > tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' ; echo
  "files/alphanumeric-secret.age".publicKeys = all;

  # Private key used by btrkbk to send backups
  # > ssh-keygen -t ed25519 -C btrbk -f /tmp/btrbk
  "files/btrbk-key.age".publicKeys = all;

  # Environment variables used by Immich
  "files/immich-env.age".publicKeys = all;

  "files/withings-env.age".publicKeys = all;

  # Environment variables used by OCIS
  # ---------------------------------------------------------------------------
  # IDM_ADMIN_PASSWORD=xxxxxxxxxxxxxxx;
  # NOTIFICATIONS_SMTP_HOST=smtp.example.com;
  # NOTIFICATIONS_SMTP_PORT=587
  # NOTIFICATIONS_SMTP_SENDER=user@example.com
  # NOTIFICATIONS_SMTP_PASSWORD=xxxxxxxxxxxx
  "files/ocis-env.age".publicKeys = all;
  "files/rclone-conf.age".publicKeys = all;

  "files/blobfuse.yaml.age".publicKeys = all;

}
