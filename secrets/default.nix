{ lib, config, ... }: with lib; {

  # Public keys
  options.keys = mkOption { type = types.attrs; };
  config.keys = import ./keys.nix;

  # Secret files
  config.age.secrets = with config.services; {

    alphanumeric-secret.file = ./alphanumeric-secret.age;
    basic-auth = mkIf traefik.enable { file = ./basic-auth.age; owner = "traefik"; };
    cloudflare-env.file = ./cloudflare-env.age;
    self-env.file = ./self-env.age;

  };

}
