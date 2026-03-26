{config, ...}: {
  home.directories = {
    # Standard user directories
    XDG_DOWNLOAD_DIR = {
      path = "downloads";
      persist = "scratch";
      enable = true;
    };
    XDG_PUBLICSHARE_DIR = {
      path = "public";
      persist = "storage";
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
    XDG_BIN_DIR = {
      path = "bin";
      persist = "storage";
      enable = true;
    };
    XDG_ORG_DIR = {
      path = "org";
      enable = true;
    };
    XDG_NOTES_DIR = {
      path = "notes";
      persist = "storage";
      enable = true;
    };
    XDG_SOURCE_DIR = {
      path = "src";
      persist = "storage";
      enable = true;
    };
    XDG_WORKSPACE_DIR = {
      path = "workspace";
      persist = "storage";
      enable = true;
    };
  };

  # Code cloned here, auto-whitelist for direnv
  programs.direnv.config.whitelist.prefix = [
    config.xdg.userDirs.extraConfig.XDG_SOURCE_DIR
  ];

  persist.storage.directories = [
    ".local/state/nix" # persist pkg installs to nix profile
  ];
  persist.storage.files = [];
}
