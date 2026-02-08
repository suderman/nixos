{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.lua;
  luarocksDir = ".local/share/luarocks";
in {
  options.programs.lua.enable = lib.mkEnableOption "lua";

  config = lib.mkIf cfg.enable {
    persist.scratch.directories = [luarocksDir];

    home.sessionVariables = {
      LUAROCKS_CONFIG = "${config.home.homeDirectory}/${luarocksDir}/config.lua";
    };

    home.sessionPath = [
      "${config.home.homeDirectory}/${luarocksDir}/bin"
    ];

    home.packages = [
      pkgs.lua # lua luac
      pkgs.luaPackages.luarocks # luarocks luarocks-admin
      pkgs.gcc
      pkgs.gnumake
      pkgs.pkg-config
    ];

    # default config for user-local installs
    home.file."${luarocksDir}/config.lua".text = ''
      rocks_trees = {
        {
          name = "user",
          root = "${config.home.homeDirectory}/${luarocksDir}"
        }
      }
    '';
  };
}
