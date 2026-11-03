{
  config,
  lib,
  pkgs,
  ...
}: {
  options.programs.linode-cli.enable = lib.mkEnableOption "Linode CLI";

  config = lib.mkIf config.programs.linode-cli.enable {
    home.packages = [pkgs.linode-cli];
    # The CLI stores all users and tokens in a single writable INI file.
    persist.storage.files = [".config/linode-cli"];
  };
}
