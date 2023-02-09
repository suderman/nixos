{ lib, config, ... }: with lib; {

  options.secrets = mkOption { type = types.attrs; };

  config.secrets = {

    # Host should have to opt into secrets
    enable = false;

    # Public keys
    keys = import ./keys;

    # Encrypted files
    files = import ./files;

  };

}
