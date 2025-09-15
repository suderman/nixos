{config, ...}: {
  # Personal browser extensions
  programs.chromium.externalExtensions = {
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

  # Pixel Buds Pro
  programs.rofi.extraSinks = ["bluez_output.AC_3E_B1_9F_43_35.1"];
}
