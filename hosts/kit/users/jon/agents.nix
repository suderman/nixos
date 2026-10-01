{config, ...}: {
  programs.hermes = {
    enable = true;
    camofoxUrl = config.services.camofox-browser.apiUrls.hermes;
  };

  services.camofox-browser = {
    enable = true;
    enableVnc = true;
    profiles = ["hermes"];
  };
}
