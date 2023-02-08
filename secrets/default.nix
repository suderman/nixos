{ lib, config, ... }: with lib; {

  # Public keys
  options.keys = mkOption { type = types.attrs; };
  config.keys = import ./pub;

  # Secret files
  options.secrets = mkOption { type = types.attrs; };
  config.secrets = import ./age;

}
