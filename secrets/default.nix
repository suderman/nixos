{ lib, ... }: with lib; {

  # Public keys
  options.keys = mkOption { type = types.attrs; };
  config.keys = import ./keys.nix;

  # Secret files
  config.age.secrets = {

    alphanumeric-secret.file = ./alphanumeric-secret.age;
    basic-auth = { file = ./basic-auth.age; owner = "traefik"; };
    cloudflare-env.file = ./cloudflare-env.age;
    self-env.file = ./self-env.age;

  };

}
