{config, ...}: {
  programs.hermes = {
    enable = true;
    camofoxUrl = config.services.camofox-browser.apiUrls.hermes;
  };

  programs.june = {
    daemon.enable = true;
    envFile = ./june-env.age;
  };

  services.camofox-browser = {
    enable = true;
    enableVnc = true;
    profiles = ["hermes"];
  };
}
