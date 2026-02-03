{config, ...}: {
  # Personal browser extensions
  programs = config.desktop {
    chromium.externalExtensions = {
      inherit
        (config.programs.chromium.registry)
        auto-tab-discard-suspend
        dark-reader
        fake-data
        floccus-bookmarks-sync
        i-still-dont-care-about-cookies
        one-password
        return-youtube-dislike
        sponsorblock
        ublock-origin
        ;
    };
  };
}
