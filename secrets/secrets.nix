let keys = import ./keys; in {

  # ---------------------------------------------------------------------------
  # How to manage secrets
  # ---------------------------------------------------------------------------
  #
  # Add a new line (like below): 
  # > "my-password.age".publicKeys = all;
  #
  # Open a shell in the ./secrets directory and run:
  # > agenix -e "my-password.age"
  #
  # Edit ./secrets/default.nix and add this attribute:
  # > my-password = ./my-password.age;
  #
  # You can now refer to the secret later in the config like so:
  # > nixos (agenix)
  # age.secrets = with config.secrets; {
  #   my-password.file = my-password;
  #   my-password.owner = "me";
  # };
  # > home-manager (homeage)
  # homeage.file = with config.secrets; {
  #   my-password.source = my-password;
  #   my-password.symlinks = [ "${config.xdg.configHome}/my-password.txt" ];
  # };


  # ---------------------------------------------------------------------------
  # List of secrets
  # ---------------------------------------------------------------------------

  # Long secret with characters constrained to alphabet and digits
  # > tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' ; echo
  # > agenix -e alphanumeric-secret.age
  "files/alphanumeric-secret.age".publicKeys = keys.all;

  # Basic Auth for traefik
  # > nix shell nixpkgs#apacheHttpd -c htpasswd -nb USERNAME PASSWORD
  # > USERNAME:$apr1$9GXtleUd$Bc0cNYaR42mIUvys6zJfB/
  # > agenix -e basic-auth.age
  "files/basic-auth.age".publicKeys = keys.all;

  # CloudFlare DNS API Token used by Traefik & Let's Encrypt
  # > agenix -e cloudflare-env.age
  # > CF_DNS_API_TOKEN=xxxxxx
  "files/cloudflare-env.age".publicKeys = keys.all;

  # .env for most of my self-hosted services 
  # > agenix -e self-env.age
  "files/self-env.age".publicKeys = keys.all;

  # Encrypted password for NixOS user account
  # > mkpasswd -m sha-512 mySecr3tpa$$w0rd!
  # > agenix -e password.age
  "files/password.age".publicKeys = keys.all;

  # .env for tailscale-cloudflare-dnssync
  # > agenix -e cloudflare-tailscale.age
  # cf-key=<https://dash.cloudflare.com/profile/api-tokens>
  # cf-domain=example.com
  # ts-key=<https://login.tailscale.com/admin/settings/keys>
  # ts-tailnet=example.github
  "files/tailscale-cloudflare.age".publicKeys = keys.all;

  "files/foo.age".publicKeys = keys.all;

}
