{ config, lib, ... }: with lib; {

  options.modules.secrets = mkOption { type = types.attrs; };

  config.modules.secrets = {

    # Host should have to opt into secrets
    enable = false;

    # Public keys
    keys = import ./keys;

    # Encrypted files
    files = import ./files;

  };

}
