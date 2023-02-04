{ lib, config, ... }: with lib; {

  # Public keys
  options.keys = mkOption { type = types.attrs; };
  config.keys = import ./keys;

  
  # Secret files
  options.secrets = mkOption { type = types.attrs; };
  config.secrets = {

    # Host should have to opt into secrets
    enable = false; 

    # Each encrypted file in this directory
    alphanumeric-secret  = ./alphanumeric-secret.age;
    basic-auth           = ./basic-auth.age;
    cloudflare-env       = ./cloudflare-env.age;
    password             = ./password.age;
    self-env             = ./self-env.age;
    tailscale-cloudflare = ./tailscale-cloudflare.age;

  };

}
