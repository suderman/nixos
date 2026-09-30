_: {
  programs.hermes.enable = true;

  # Keep the existing browser instances independent of Hermes profiles.
  services.camofox-browser = {
    enable = true;
    enableVnc = true;
    profiles = ["june" "pax"];
  };
}
