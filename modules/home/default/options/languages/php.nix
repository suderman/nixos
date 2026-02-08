{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.php;
  composerDir = ".local/share/composer";
in {
  options.programs.php.enable = lib.mkEnableOption "php";

  config = lib.mkIf cfg.enable {
    persist.scratch.directories = [composerDir];

    home.sessionVariables = {
      COMPOSER_HOME = "${config.home.homeDirectory}/${composerDir}";
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/${composerDir}/vendor/bin"
    ];

    home.packages = [
      pkgs.php # php php-fpm pecl phar pear peardev
      pkgs.phpPackages.composer # composer compile
    ];
  };
}
