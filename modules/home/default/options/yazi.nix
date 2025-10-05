{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.yazi;
  inherit (builtins) baseNameOf;
  inherit (lib) mkIf;

  dir = with config.xdg.userDirs; rec {
    home = config.home.homeDirectory;
    desktop = extraConfig.XDG_DESKTOP_DIR or "${home}/Desktop";
    documents = extraConfig.XDG_DOCUMENTS_DIR or "${home}/Documents";
    download = extraConfig.XDG_DOWNLOAD_DIR or "${home}/Downloads";
    games = extraConfig.XDG_GAMES_DIR or "${home}/Games";
    music = extraConfig.XDG_MUSIC_DIR or "${home}/Music";
    notes = extraConfig.XDG_NOTES_DIR or "${home}/Notes";
    pictures = extraConfig.XDG_PICTURES_DIR or "${home}/Pictures";
    publicShare = extraConfig.XDG_PUBLICSHARE_DIR or "${home}/Public";
    source = extraConfig.XDG_SOURCE_DIR or "${home}/Source";
    templates = extraConfig.XDG_TEMPLATES_DIR or "${home}/Templates";
    videos = extraConfig.XDG_VIDEOS_DIR or "${home}/Videos";
  };
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

      settings.opener.default = [
        {
          run = ''xdg-open "$@"'';
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
        {
          mime = "video/*";
          use = "video";
        }
        {
          mime = "audio/*";
          use = "audio";
        }
        {
          mime = "image/*";
          use = ["image" "edit-image"];
        }
        {
          name = "*";
          use = "default";
        }
      ];

      keymap.mgr.prepend_keymap = [
        {
          on = "?"; # display keymaps
          run = "help";
        }
        {
          on = "<Space>";
          run = "toggle";
        }
        {
          on = "M";
          run = "plugin mount";
        }
        {
          on = "z";
          run = "plugin zoxide";
        }
        {
          on = "Z";
          run = "plugin fzf";
        }
        {
          on = ["d" "d"];
          run = "remove --force";
          desc = "delete into trash";
        }
        {
          on = ["d" "r"];
          run = "remove --permanently";
          desc = "delete for realz";
        }
        {
          on = "i";
          run = "spot";
          desc = "info";
        }
        {
          on = ["g" "h" "h"];
          run = "cd ${dir.home}";
          desc = "go home";
        }
        {
          on = ["g" "h" "j"];
          run = "cd ${dir.download}";
          desc = "go downloads";
        }
        {
          on = ["g" "h" "k"];
          run = "cd ${dir.desktop}";
          desc = "go desktop";
        }
        {
          on = ["g" "h" "b"];
          run = "cd ${dir.documents}";
          desc = "go documents";
        }
        {
          on = ["g" "h" "i"];
          run = "cd ${dir.pictures}";
          desc = "go pictures";
        }
        {
          on = ["g" "h" "v"];
          run = "cd ${dir.videos}";
          desc = "go videos";
        }
        {
          on = ["g" "h" "m"];
          run = "cd ${dir.music}";
          desc = "go music";
        }
        {
          on = ["g" "h" "g"];
          run = "cd ${dir.games}";
          desc = "go games";
        }
        {
          on = ["g" "h" "s"];
          run = "cd ${dir.source}";
          desc = "go source";
        }
        {
          on = ["g" "h" "n"];
          run = "cd ${dir.notes}";
          desc = "go notes";
        }
        {
          on = ["g" "m"];
          run = "plugin mount";
          desc = "go mounts";
        }
        {
          on = ["g" "c"];
          run = "cd /etc/nixos";
        }
        {
          on = ["g" "d"];
          run = ''shell 'ripdrag "$@" -x 2>/dev/null &' --confirm'';
          desc = "ripdrag";
        }
        {
          on = ["g" "s" "t"]; # gst -> storage
          run = "cd /mnt/main/storage";
        }
        {
          on = ["g" "s" "c"]; # gst -> scratch
          run = "cd /mnt/main/scratch";
        }
      ];

      theme.icon.append_dirs = [
        {
          name = baseNameOf dir.desktop;
          text = "";
        }
        {
          name = baseNameOf dir.download;
          text = "";
        }
        {
          name = baseNameOf dir.music;
          text = "";
        }
        {
          name = baseNameOf dir.pictures;
          text = "";
        }
        {
          name = baseNameOf dir.documents;
          text = "";
        }
        {
          name = baseNameOf dir.publicShare;
          text = "";
        }
        {
          name = baseNameOf dir.notes;
          text = "";
        }
        {
          name = baseNameOf dir.videos;
          text = "";
        }
        {
          name = baseNameOf dir.games;
          text = "";
        }
        {
          name = baseNameOf dir.source;
          text = "";
        }
        {
          name = "nixos";
          text = "";
        }
      ];

      initLua =
        # lua
        ''

        '';
    };
  };
}
