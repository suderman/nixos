{config, ...}: {
  home.directories = {
    # Standard user directories
    XDG_DOWNLOAD_DIR = {
      path = "downloads";
      persist = "scratch";
      sync = false;
      enable = true;
    };
    XDG_PUBLICSHARE_DIR = {
      path = "public";
      persist = "storage";
      sync = true;
      enable = true;
    };

    # Standard user directories (disabled)
    XDG_DESKTOP_DIR.enable = false;
    XDG_DOCUMENTS_DIR.enable = false;
    XDG_MUSIC_DIR.enable = false;
    XDG_PICTURES_DIR.enable = false;
    XDG_VIDEOS_DIR.enable = false;
    XDG_TEMPLATES_DIR.enable = false;

    # Custom user directories
    XDG_SOURCE_DIR = {
      path = "src";
      persist = "storage";
      sync = false;
      enable = true;
    };
    XDG_WORKSPACE_DIR = {
      path = "workspace";
      persist = "storage";
      sync = true;
      enable = true;
    };
  };

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    config.xdg.userDirs.extraConfig.XDG_SOURCE_DIR
  ];

  persist.storage.directories = [
    ".local/state/nix" # persist pkg installs to nix profile
    ".local/bin" # persist local scripts
  ];
  persist.storage.files = [];
}
