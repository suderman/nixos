{config, ...}: {
  # Personal browser extensions
  programs = config.desktop {
    chromium.externalExtensions = {
      inherit
        (config.programs.chromium.registry)
        dark-reader
        fake-data
        i-still-dont-care-about-cookies
        sponsorblock
        ublock-origin
        ;
    };
  };
}
