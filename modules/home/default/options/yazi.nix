{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.yazi;
  inherit (lib) mkIf;
  plugins = {
    # https://github.com/yazi-rs/plugins/
    yazi = pkgs.fetchFromGitHub {
      owner = "yazi-rs";
      repo = "plugins";
      rev = "40eafa3e4c7383db865ac1d61bbc0fa22be0ef01";
      hash = "sha256-Ey3lDmhFLpp/sD3sC/kNgsN7JZz+i2dU+bvqKODOxzo=";
    };

    # https://github.com/boydaihungst/simple-mtpfs.yazi
    simple-mtpfs = pkgs.fetchFromGitHub {
      owner = "boydaihungst";
      repo = "simple-mtpfs.yazi";
      rev = "eb21ae5b73ea08d62e07256e92a89b1b4a0b81fd";
      hash = "sha256-s+fNoH5wuhk43qxPplYECSX/aWFG2UWEHkow32xsacM=";
    };

    # https://github.com/Rolv-Apneseth/starship.yazi
    starship = pkgs.fetchFromGitHub {
      owner = "Rolv-Apneseth";
      repo = "starship.yazi";
      rev = "247f49da1c408235202848c0897289ed51b69343";
      hash = "sha256-0J6hxcdDX9b63adVlNVWysRR5htwAtP5WhIJ2AK2+Gs=";
    };
  };
in {
  config = mkIf cfg.enable {
    programs.yazi = {
      shellWrapperName = "y";

      plugins = {
        chmod = "${plugins.yazi}/chmod.yazi";
        simple-mtpfs = plugins.simple-mtpfs;
        starship = plugins.starship;
      };

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      enableFishIntegration = true;

      settings.manager = {
        sort_dir_first = true;
        linemode = "permissions";
        ratio = [1 3 4];
      };

      settings.preview = {
        tab_size = 4;
        image_filter = "lanczos3";
        max_width = 1920;
        max_height = 1080;
        image_quality = 90;
      };

      keymap.manager.prepend_keymap = [
        {
          run = "remove --force";
          on = ["d"];
        }
      ];
    };
  };
}
