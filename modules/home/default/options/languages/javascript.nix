{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.javascript;
  npmDir = ".local/share/npm";
  pnpmDir = ".local/share/pnpm";
  bunDir = ".local/share/bun";
in {
  options.programs.javascript.enable = lib.mkEnableOption "javascript";
  config = lib.mkIf cfg.enable {
    persist.scratch.directories = [npmDir pnpmDir bunDir];
    home.sessionVariables = rec {
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/${npmDir}";
      NPM_CONFIG_CACHE = "${config.home.homeDirectory}/${npmDir}/cache";
      PNPM_HOME = "${config.home.homeDirectory}/${pnpmDir}";
      PNPM_STORE_DIR = "${PNPM_HOME}/store";
      BUN_INSTALL = "${config.home.homeDirectory}/${bunDir}";
      BUN_INSTALL_CACHE_DIR = "${BUN_INSTALL}/install/cache";
    };
    home.sessionPath = [
      "${config.home.homeDirectory}/${npmDir}/bin"
      "${config.home.homeDirectory}/${pnpmDir}"
      "${config.home.homeDirectory}/${bunDir}/bin"
    ];
    xdg.configFile."pnpm/rc".text = ''
      global-bin-dir=${config.home.homeDirectory}/${pnpmDir}
    '';
    home.packages = [
      pkgs.nodejs # node npm npx
      pkgs.pnpm # pnpm pnpx
      pkgs.bun # bun bunx
    ];
  };
}
