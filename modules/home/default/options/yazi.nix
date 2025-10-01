{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.yazi;
  inherit (builtins) baseNameOf;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    programs.yazi = {
      shellWrapperName = "y";

      plugins = {
        mount = pkgs.yaziPlugins.mount;
        chmod = pkgs.yaziPlugins.chmod;
        starship = pkgs.yaziPlugins.starship;
        # gvfs = pkgs.fetchFromGitHub {
        #   owner = "boydaihungst";
        #   repo = "gvfs.yazi";
        #   rev = "f07b496922c25c89c62305a292c6a53ccb4670cd";
        #   hash = "sha256-s+fNoH5wuhk43qxPplYECSX/aWFG2UWEHkow32xsacM=";
        # };
      };

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      enableFishIntegration = true;

      settings.mgr = {
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

      settings.opener.pdf = [
        {
          run = ''zathura "$@"'';
          desc = "View PDF in Zathura";
          block = false;
          orphan = true;
          for = "unix";
        }
      ];

      settings.open.rules = [
        {
          name = "*.pdf";
          use = "pdf";
        }
      ];

      keymap.mgr.prepend_keymap = [
        {
          on = "M";
          run = "plugin mount";
        }
        {
          on = ["d"];
          run = "remove --force";
        }
      ];

      theme.icon.append_dirs = with config.xdg.userDirs; [
        {
          name = baseNameOf (extraConfig.XDG_DESKTOP_DIR or "Desktop");
          text = "";
        }
        {
          name = baseNameOf (extraConfig.XDG_DOWNLOAD_DIR or "Downloads");
          text = "";
        }
        {
          name = baseNameOf (extraConfig.XDG_MUSIC_DIR or "Music");
          text = "";
        }
        {
          name = baseNameOf (extraConfig.XDG_PICTURES_DIR or "Pictures");
          text = "";
        }
        {
          name = baseNameOf (extraConfig.XDG_DOCUMENTS_DIR or "Documents");
          text = "󰷏";
        }
        {
          name = baseNameOf (extraConfig.XDG_PUBLICSHARE_DIR or "Public");
          text = "";
        }
        {
          name = baseNameOf (extraConfig.XDG_VIDEOS_DIR or "Videos");
          text = "";
        }
        {
          name = baseNameOf (extraConfig.XDG_SOURCE_DIR or "Source");
          text = "";
        }
      ];

      initLua =
        # lua
        ''

        '';
    };
  };
}
