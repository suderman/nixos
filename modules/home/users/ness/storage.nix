{...}: {
  home.directories = {
    XDG_DESKTOP_DIR.persist = "storage";
    XDG_DOWNLOAD_DIR.persist = "scratch";
    XDG_DOCUMENTS_DIR.persist = "storage";
    XDG_MUSIC_DIR.persist = "storage";
    XDG_PICTURES_DIR.persist = "storage";
    XDG_VIDEOS_DIR.persist = "storage";
    XDG_PUBLICSHARE_DIR.enable = false;
    XDG_TEMPLATES_DIR.enable = false;
  };
}
