{ lib, config, ... }: with lib; {

  # Public keys
  options.keys = mkOption { type = types.attrs; };
  config.keys = import ./pub;

  # Secret files
  options.secrets = mkOption { type = types.attrs; };
  config.secrets = import ./age;

  # config.secrets = {
  #
  #   # Host should have to opt into secrets
  #   enable = false; 
  #
  #   # Each encrypted file in this directory
  #   alphanumeric-secret  = ./age/alphanumeric-secret.age;
  #   basic-auth           = ./age/basic-auth.age;
  #   cloudflare-env       = ./age/cloudflare-env.age;
  #   password             = ./age/password.age;
  #   self-env             = ./age/self-env.age;
  #   tailscale-cloudflare = ./age/tailscale-cloudflare.age;
  #
  # };
  #
  # config.secrets = ( import ./age ) // {
  #
  #   # Host should have to opt into secrets
  #   enable = false;
  #
  # }

}
