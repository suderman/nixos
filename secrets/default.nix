{ lib, config, ... }: with lib; {

  # Public keys
  options.keys = mkOption { type = types.attrs; };
  config.keys = import ./keys.nix;
  
  # Secret files
  options.secrets = mkOption { type = types.attrs; };
  config.secrets = {
    alphanumeric-secret = ./alphanumeric-secret.age;
    basic-auth          = ./basic-auth.age;
    cloudflare-env      = ./cloudflare-env.age;
    self-env            = ./self-env.age;
    password            = ./password.age;
  };

}
